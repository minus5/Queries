#import "TdsConnection.h"

@implementation TdsConnection                                

//@synthesize messages, results;
@synthesize isProcessing; 
  

NSMutableArray *activeConnections;

+ (void) activate: (TdsConnection*) conn{
	if (!activeConnections){
		activeConnections = [NSMutableArray array];
		[activeConnections retain];
	}                                            
	[activeConnections addObject: conn];
}    

+ (void) deactivate: (TdsConnection*) conn{
	for(id c in activeConnections){
		if ((TdsConnection*)c == conn){
			[activeConnections removeObject: c];
			break;
		}
	}
}       

- (DBPROCESS*) dbproc{
	return dbproc;
}    

+ (void) logMessage: (NSString*) message forProcess: (DBPROCESS*) dbproc{
	for(id c in activeConnections){
		if ([c dbproc] == dbproc){
			[c logMessage: message];
			return;
		}
	}                                           
	NSLog(@"logMessage failed, process not found?!");
}

//TdsConnection *active;
int msg_handler(DBPROCESS *dbproc, DBINT msgno, int msgstate, int severity, char *msgtext, char *srvname, char *procname, int line)
{									
	enum {changed_database = 5701, changed_language = 5703 };	
	
	if (msgno == changed_database || msgno == changed_language) 
		return 0;
	
	NSMutableString *message = [NSMutableString stringWithCapacity:0];
	if (msgno > 0) {
		[message appendFormat: @"Msg %ld, Level %d, State %d\n", (long) msgno, severity, msgstate];
		
		// if (strlen(srvname) > 0)
		// 	[message appendFormat:@"Server '%s', ", srvname];
		if (strlen(procname) > 0)
			[message appendFormat:@"Procedure '%s', ", procname];
		if (line > 0)
			[message appendFormat:@"Line %d", line];		
	}	          
	if ([message length] > 0)
		[message appendFormat:@"\n"];
	if (strlen(msgtext) > 0)
		[message appendFormat:@"%s\n", msgtext];
	if ([message length] > 0){
		[TdsConnection logMessage:message forProcess: dbproc];	
		//NSLog(@"%@", message);  
	}
		
	// if (severity > 10) {						
	// 	[active logMessage:message];
	// 	[NSException raise:@"Exception" format: @"error: severity %d\n", severity];
	// }                           
	// else{
	 // [active logMessage:message];
	//	[TdsConnection logMessage:message forProcess: dbproc];	
	// }
	
	return 0;							
}

int err_handler(DBPROCESS *dbproc, int severity, int dberr, int oserr, char *dberrstr, char *oserrstr)
{	
	if ([[NSString stringWithFormat: @"%s", dberrstr] isEqualToString: @"Data conversion resulted in overflow"]){
		NSLog(@"ignoring message 'Data conversion resulted in overflow'");
		return INT_CANCEL;
	}
	
	if ([[NSString stringWithFormat: @"%s", dberrstr] isEqualToString: @"Server name not found in configuration files"]){
		NSLog(@"ignoring message 'Server name not found in configuration files'");
		return INT_CANCEL;
	}	
		
	NSMutableString *message = [NSMutableString stringWithCapacity:0];
	if (dberr) {							
		[message appendFormat:@"Error Msg %d, Level %d\n", dberr, severity];
		[message appendFormat:@"%s\n", dberrstr];
	}	
	else {
		[message appendFormat:@"DB-LIBRARY error:\n\t"];
		[message appendFormat:@"%s\n", dberrstr];
	}
	
	[TdsConnection logMessage:message forProcess: dbproc];	
	return INT_CANCEL;						
}    

struct COL 						
{ 
	char *name; 
	char *buffer; 
	int type, size, status; 
};

-(void) login{
	LOGINREC *login;	
	//RETCODE erc;
	
	setenv("TDSPORT", "1433", 1);
	setenv("TDSVER", "8.0", 1);
	dbsetlogintime(10);
			
	if (dbinit() == FAIL) {
		[NSException raise:@"Exception" format: @"%d: dbinit() failed\n", __LINE__];
	}
		
	dberrhandle(err_handler);
	dbmsghandle(msg_handler);
		
	if ((login = dblogin()) == NULL) {
		[NSException raise:@"Exception" format: @"%d: unable to allocate login structure\n", __LINE__];
	}
		
	DBSETLUSER(login, [_userName cStringUsingEncoding:NSASCIIStringEncoding]);
	DBSETLPWD(login, [_password cStringUsingEncoding:NSASCIIStringEncoding]);
	
	dbsetlname(login, "UTF-8", DBSETCHARSET);
			
	if ((dbproc = dbopen(login, [_serverName cStringUsingEncoding:NSASCIIStringEncoding])) == NULL) {
		[NSException raise:@"Exception" format: @"%d: unable to connect to %s as %s\n", __LINE__, [_serverName cStringUsingEncoding:NSASCIIStringEncoding], [_userName cStringUsingEncoding:NSASCIIStringEncoding]];
	}

	/*	
	if ([_databaseName cStringUsingEncoding:NSASCIIStringEncoding]  && (erc = dbuse(dbproc, [_databaseName cStringUsingEncoding:NSASCIIStringEncoding])) == FAIL) {
		[NSException raise:@"Exception" format: @"%d: unable to use to database %s\n", __LINE__, _databaseName];
	}	
	*/			
	
}

-(void) executeQuery: (NSString*) query{
	RETCODE erc;
	
	if ((erc = dbfcmd(dbproc, "%s ", [query cStringUsingEncoding:NSASCIIStringEncoding])) == FAIL) {
		[NSException raise:@"Exception" format: @"%d: dbcmd() failed\n", __LINE__];
	}		
	if ((erc = dbsqlexec(dbproc)) == FAIL) {
		[NSException raise:@"Exception" format: @"%d: dbsqlexec() failed\n", __LINE__];		
	}
}

-(NSArray*) readResultMetadata: (struct COL**) pcolumns{
	RETCODE erc;
	struct COL *pcol, *columns;
	int ncols;
	
	if (erc == FAIL) {
		[NSException raise:@"Exception" format: @"%d: dbresults failed\n", __LINE__];
	}
	
	ncols = dbnumcols(dbproc);
	
	if ((columns = calloc(ncols, sizeof(struct COL))) == NULL) {
		perror(NULL);
		[NSException raise:@"Exception" format: @"%d: calloc failed\n", __LINE__];
	}
	
	NSMutableArray *columnNames = [NSMutableArray arrayWithCapacity:ncols];			
	
	for (pcol = columns; pcol - columns < ncols; pcol++) {
		int columnIndex = pcol - columns + 1;
		
		pcol->name = dbcolname(dbproc, columnIndex);		
		pcol->type = dbcoltype(dbproc, columnIndex);
		pcol->size = dbcollen(dbproc, columnIndex);
		
		if (SYBCHAR != pcol->type) {			
			pcol->size = dbwillconvert(pcol->type, SYBCHAR);
		}		
		
		ColumnMetadata *meta = [ColumnMetadata alloc];
		[meta initWithName:[[NSString alloc] initWithCString: pcol->name encoding:NSWindowsCP1250StringEncoding] size: pcol->size type:pcol->type index: (pcol - columns)];
		
		[columnNames addObject: meta];
		
		if ((pcol->buffer = calloc(1, pcol->size + 1)) == NULL){
			perror(NULL);
			[NSException raise:@"Exception" format: @"%d: calloc failed\n", __LINE__];
		}
		
		erc = dbbind(dbproc, columnIndex, NTBSTRINGBIND, pcol->size+1, (BYTE*)pcol->buffer);
		if (erc == FAIL) {
			[NSException raise:@"Exception" format: @"%d: dbbind(%d) failed\n", __LINE__, columnIndex];
		}
		
		erc = dbnullbind(dbproc, columnIndex, &pcol->status);	
		if (erc == FAIL) {
			[NSException raise:@"Exception" format: @"%d: dbnullbind(%d) failed\n", __LINE__, columnIndex];
		}
	}	
	
	*pcolumns = columns;	
	return columnNames;
}

-(NSArray*) readResultData: (struct COL*) columns{
	int row_code;
	struct COL *pcol;
	int ncols = dbnumcols(dbproc);

	
	NSMutableArray *rows = [NSMutableArray array];
	
	//-----data
	while ((row_code = dbnextrow(dbproc)) != NO_MORE_ROWS){	
		switch (row_code) {
			case REG_ROW:
			{
				NSMutableArray *rowValues = [NSMutableArray arrayWithCapacity: ncols];
				for (pcol=columns; pcol - columns < ncols; pcol++) {															
					char *buffer = pcol->status == -1? "NULL" : pcol->buffer;																	
					NSString *value = [[NSString alloc] initWithCString: buffer encoding:NSWindowsCP1250StringEncoding];															
					[rowValues addObject: value];					
				}				
				[rows addObject: rowValues];				
			}
				break;
				
			case BUF_FULL:
				assert(row_code != BUF_FULL);
				break;
				
			case FAIL:
				[NSException raise:@"Exception" format: @"%d: dbresults failed\n", __LINE__];
				break;
				
			default: 					
				NSLog(@"Data for computeid %d ignored\n", row_code);
		}				
	}
	return rows;
}

-(void) freeResultBuffers: (struct COL*) columns{
	struct COL *pcol;
	int ncols = dbnumcols(dbproc);		

	for (pcol=columns; pcol - columns < ncols; pcol++) {     
		free(pcol->buffer);
	}
	free(columns);
}

-(void) readResultMessages{
	//Get row count, if available.   
	if (DBCOUNT(dbproc) > -1){
		[self logMessage: [NSString stringWithFormat:@"%d rows affected\n", DBCOUNT(dbproc)]];
		NSLog(@"%d rows affected\n", DBCOUNT(dbproc));
	}
	
	//Check return status 			 
	if (dbhasretstat(dbproc) == TRUE) {
		[self logMessage: [NSString stringWithFormat:@"Procedure returned %d\n", dbretstatus(dbproc)]];
		NSLog(@"Procedure returned %d\n", dbretstatus(dbproc));
	}
}

-(void) readResults{
	RETCODE erc;		 
			
	while ((erc = dbresults(dbproc)) != NO_MORE_RESULTS) {
		
		struct COL *columns;		
		@try {
			NSArray *columnNames = [self readResultMetadata: &columns];
			NSArray *rows = [self readResultData: columns];			
			[queryResult addResultWithColumnNames: columnNames andRows: rows];			
			[self readResultMessages];       			                            
			
			// if (!([columnNames count] == 0 && [rows count] == 0)){
			// 	[results addObject: [NSArray arrayWithObjects: columnNames, rows, nil]];					
			// 	[columnNames retain];
			// 	[rows retain];
			// }
		}
		@catch (NSException *e) {
			@throw;
		}
		@finally {
			[self freeResultBuffers: columns];
		}																
	}			
}         


- (void) checkConnection{
	if (dbproc == nil){ 
		NSLog(@"Reconnecting...");
		[self login];
	}	
}                          

- (void) useDatabase: (NSString*) database{ 
	if (database && (dbuse(dbproc, [database cStringUsingEncoding:NSASCIIStringEncoding])) == FAIL) {
		[NSException raise:@"Exception" format: @"%d: unable to use to database %s\n", __LINE__, database];
	}
}
        
- (void) executeQueries: (NSString*) query{
	dbsettime(30);			  
	NSArray *queries = [query componentsSeparatedByString: @"GO"];
	for(id query in queries){
		NSLog(@"executing query: %@", query);
		[self executeQuery: query];				
		[self readResults];
	}	
}         

-(void) executeInBackground: (NSDictionary*) arguments{     
	if ([self isProcessing]) return;			
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
		         
	NSString *query = [arguments objectForKey: @"query"];
	NSString *database = [arguments objectForKey: @"database"];
	id receiver = [arguments objectForKey: @"receiver"];
	SEL selector = NSSelectorFromString([arguments objectForKey: @"selector"]); //@selector(setResult:);	
  
  QueryResult *result = [self execute: query withDefaultDatabase: database];	
	
	[receiver performSelectorOnMainThread: selector withObject: result waitUntilDone: YES];		
                                                                                        
	[pool release];
}

-(QueryResult*) execute: (NSString*) query withDefaultDatabase: (NSString*) database{
	[TdsConnection activate: self];
	QueryResult *result = [[QueryResult alloc] init];
	[result retain];
	queryResult = result;		
	@try{                                       
		[self setIsProcessing: TRUE]; 

		[self checkConnection];
		[self useDatabase: database]; 
		[self executeQueries: query];
		[queryResult addCompletedMessage];																		
	}
	@catch (NSException *exception) {    
		[self logout];
		[self logMessage: [NSString stringWithFormat:@"%@", [exception reason]]];
	} 
	@finally{
		[TdsConnection deactivate: self];
		[self setIsProcessing: FALSE];
	}   
	queryResult = nil;
	return result;
} 
 
-(QueryResult*) execute: (NSString*) query{  
	return [self execute: query withDefaultDatabase: nil];		
}

-(void) logout{
	if (dbproc){
		dbclose(dbproc);			
		dbexit();	      
		dbproc = nil;
	}
}

-(void) dealloc{    
	NSLog(@"QueryExec dealloc");
	[self logout]; 
	//[queryResult release];
	[super dealloc];
}

-(void) logMessage: (NSString*) message{
	if (queryResult){
		[queryResult addMessage: message];
	}else{
		NSLog(@"missing queryResult in logMessage");
	}
}

-(id) initWithCredentials: (NSString*) serverName 
			userName: (NSString*) userName 
			password: (NSString*) password
{
	self = [super init];
	
	if(self){
		_serverName = [[NSString alloc] initWithString: serverName];
		_userName = [[NSString alloc] initWithString:userName];
		_password = [[NSString alloc] initWithString: password];
	}
	
	return self;
}    

- (TdsConnection*) clone{
	return [[TdsConnection alloc] initWithCredentials: _serverName userName: _userName password: _password];
}

-(NSString*) connectionName{
	return [NSString stringWithFormat: @"%@@%@", _userName, _serverName];
}

-(NSString*) currentDatabase{                            
	if (!dbproc)
		return nil;
				
	@try{	                                                 		
		return [[NSString alloc] initWithCString: dbname(dbproc) encoding:NSWindowsCP1250StringEncoding];
	}
	@catch(NSException *e){
		NSLog(@"defaultDatabase exception: @%", e);
		return nil;
	}
} 

@end
