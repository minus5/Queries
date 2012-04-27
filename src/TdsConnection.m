#import "TdsConnection.h"
#import "CredentialsController.h"
#import "Constants.h"

@implementation TdsConnection                                

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

+ (void) logMessage: (NSString*) message forProcess: (DBPROCESS*) dbproc error: (BOOL)isError{
	for(id c in activeConnections){
		if ([c dbproc] == dbproc){
			[c logMessage: message error: isError];
			return;
		}
	}                                           
	NSLog(@"logMessage failed, process not found?! Message: %@", message);
}

int msg_handler(DBPROCESS *dbproc, DBINT msgno, int msgstate, int severity, char *msgtext, char *srvname, char *procname, int line)
{									
	enum {changed_database = 5701, changed_language = 5703 };	
	
	if (msgno == changed_database || msgno == changed_language) 
		return 0;
	
	NSMutableString *message = [NSMutableString stringWithCapacity:0];
	if (msgno > 0) {
		[message appendFormat: @"Msg %ld, Level %d, State %d", (long) msgno, severity, msgstate];		
		if (strlen(srvname) > 0)
		 	[message appendFormat:@", Server '%s'", srvname];
		if (strlen(procname) > 0)
			[message appendFormat:@", Procedure '%s'", procname];
		if (line > 0)
			[message appendFormat:@", Line %d", line];		
		[message appendFormat:@"\n"];		
	}	          
	if (strlen(msgtext) > 0)
		[message appendFormat:@"%s\n", msgtext];
	if ([message length] > 0){
		[TdsConnection logMessage:message forProcess: dbproc error: NO];	
	}			
	return 0;							
}

int err_handler(DBPROCESS *dbproc, int severity, int dberr, int oserr, char *dberrstr, char *oserrstr)
{	                 
	//102 i 105 je poruka 'General SQL Server error: Check messages from the SQL Server' sto ce mi to
	if (dberr != 102 &&  dberr != 105)
		{
			if ([[NSString stringWithFormat: @"%s", dberrstr] isEqualToString: @"Data conversion resulted in overflow"]){
				//NSLog(@"ignoring message 'Data conversion resulted in overflow'");
				return INT_CANCEL;
			}	
			if ([[NSString stringWithFormat: @"%s", dberrstr] isEqualToString: @"Server name not found in configuration files"]){
				//NSLog(@"ignoring message 'Server name not found in configuration files'");
				return INT_CANCEL;
			}	
		
			NSMutableString *message = [NSMutableString stringWithCapacity:0];
			if (dberr) {							
				[message appendFormat:@"Error Msg %d, Level %d\n", dberr, severity];
				[message appendFormat:@"%s\n", dberrstr];
				//[message appendFormat:@"%s\n", oserrstr];		
			}	
			else {
				[message appendFormat:@"DB-LIBRARY error:\n\t"];
				[message appendFormat:@"%s\n", dberrstr];
			}
	
			[TdsConnection logMessage:message forProcess: dbproc error: YES];	
		}
	return INT_CANCEL;						
}    



-(void) login{
	LOGINREC *login;	
	
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
		
	DBSETLUSER(login, [user UTF8String]);
	DBSETLPWD(login, [password UTF8String]);
	
	dbsetlname(login, "UTF-8", DBSETCHARSET);
			
	if ((dbproc = dbopen(login, [server UTF8String])) == NULL) {
		[NSException raise:@"Exception" format: @"%d: unable to connect to %s as %s\n", __LINE__, [server UTF8String], [user UTF8String]];
	}

	[self applyConnectionDefaults];
} 

-(void) applyConnectionDefaults{                                                                                              
	@try{
		[self executeQuery: connectionDefaults];
	} 
	@catch (NSException *e) {         
		NSLog(@"applyConnectionDefaults exception %@", e);	 
	}
}

-(NSArray*) readResultMetadata: (struct COL**) pcolumns{
	RETCODE erc;
	struct COL *pcol, *columns;
	int ncols;
			
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
        NSString *name = [[NSString alloc] initWithUTF8String: pcol->name];
		ColumnMetadata *meta = [[ColumnMetadata alloc] initWithName: name size: pcol->size type:pcol->type index: (pcol - columns)];
		[columnNames addObject: meta];
        [meta release];
        [name release];
		
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

-(NSArray*) readResultData: (struct COL*) columns  withColumnNames: (NSArray*) columnNames{
	int row_code;
	struct COL *pcol;
	int ncols = dbnumcols(dbproc);
	NSMutableArray *rows = [NSMutableArray array];
	while ((row_code = dbnextrow(dbproc)) != NO_MORE_ROWS){	
		
		if (cancelQuery && ![NSThread isMainThread]){
			@throw [NSException exceptionWithName: @"QueryCanceled" reason: @"query canceled by user" userInfo:nil]; 
		}
		
		switch (row_code) {
            case REG_ROW:
			{
				NSMutableArray *rowValues = [NSMutableArray arrayWithCapacity: ncols];
                NSString *value;        
				for (pcol=columns; pcol - columns < ncols; pcol++) {															
                    int columnIndex = pcol - columns + 1;
                    BYTE *data     = dbdata(dbproc, columnIndex);
                    if (data == NULL) {
                        value = @"NULL";
                    } else {
                        switch (pcol->type){
                            case SYBMONEY: {
                                //TODO - ovo dolje moze biti null pointer, pa se onda raspadne  
                                DBMONEY *money = (DBMONEY *)data;
                                char converted_money[25];
                                long long money_value = ((long long)money->mnyhigh << 32) | money->mnylow;
                                sprintf(converted_money, "%.5lld", money_value);
                                //converted_money is string without decimal places
                                //so add decimal sign at index 4
                                NSString *ns_converted_money = [[[NSString alloc] initWithUTF8String: converted_money]autorelease];
                                int ns_len = [ns_converted_money length];
                                value = [NSString stringWithFormat:@"%@.%@", 
                                         [ns_converted_money substringToIndex: ns_len - 4], 
                                         [ns_converted_money substringFromIndex: ns_len - 4]];
                                break;
                            }
                            case SYBMONEY4: {
                                DBMONEY4 *money = (DBMONEY4 *)data;
                                char converted_money[20];
                                sprintf(converted_money, "%f", money->mny4 / 10000.0);
                                value = [[[NSString alloc] initWithUTF8String: converted_money]autorelease];
                                break;
                            }
                            default:{
                                char *buffer = pcol->status == -1? "NULL" : pcol->buffer;
                                value = [[[NSString alloc] initWithUTF8String: buffer]autorelease];
                                if (!value)
                                    value = [[[NSString alloc] initWithCString: buffer encoding:NSASCIIStringEncoding]autorelease];
                            }
                        }
                    }
                    
					if (!value)
						value = @"???";
					
					[[columnNames objectAtIndex: (pcol - columns)] updateMaxLength: [value length]];					
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
		[self logMessage: [NSString stringWithFormat:@"%d rows affected\n", DBCOUNT(dbproc)] error: NO];
		NSLog(@"%d rows affected\n", DBCOUNT(dbproc));
	}
	
	//Check return status 			 
	if (dbhasretstat(dbproc) == TRUE) {
		[self logMessage: [NSString stringWithFormat:@"Procedure returned %d\n", dbretstatus(dbproc)] error: NO];
		NSLog(@"Procedure returned %d\n", dbretstatus(dbproc));
	}
}

-(void) readResults{
	RETCODE erc;		 
			
	while ((erc = dbresults(dbproc)) != NO_MORE_RESULTS) {
		
		struct COL *columns;		
		@try {
			NSArray *columnNames = [self readResultMetadata: &columns];
			NSArray *rows = [self readResultData: columns withColumnNames: columnNames];			
			[queryResult addResultWithColumnNames: columnNames andRows: rows];			
			[self readResultMessages];       			                            			
		}
		@catch (NSException *e) {         
			NSLog(@"exception %@", e);
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
	if (!database)
		return;
	if ((dbuse(dbproc, [database UTF8String])) == FAIL) {
		[NSException raise:@"Exception" format: @"Unable to use to database %@\n", database];
	}
}
        
- (void) executeQueries: (NSString*) query{			
	//NSLog(@"5-1 query retainCount %d", [query retainCount]);
	NSArray *queries = [query componentsSeparatedByRegex:@"^\\s*go\\s*$" options: (2 | 8) range: NSMakeRange(0, [query length]) error:nil];
	//NSLog(@"5-2 query retainCount %d", [query retainCount]);
	for(id qry in queries){		
		BOOL success = [self executeQuery: qry];				
		NSLog(@"executing query: %@ returned %d", qry, success);
		if (success)
			[self readResults];
		else
			[queryResult setHasErrors: YES];
	}	
}         

-(BOOL) executeQuery: (NSString*) qry{
	RETCODE erc = dbfcmd(dbproc, "%s ", [qry UTF8String]);
	if (erc != FAIL)               
		erc = dbsqlexec(dbproc);
	
	return (erc != FAIL);
}

- (BOOL) executeInBackground: (NSString*) query withDatabase: (NSString*) database returnToObject: (id) receiver withSelector: (SEL) selector{			
	@try{
		if ([self isProcessing]){
			return NO;
		}                             
	
		if ([receiver respondsToSelector: @selector(setExecutingConnection:)]){          
			[receiver performSelector: @selector(setExecutingConnection:) withObject: self];
		}
		if ([receiver respondsToSelector: @selector(processingStarted)]){          		
			[receiver performSelector: @selector(processingStarted)];		
		}
		
		NSDictionary *arguments = [NSDictionary dictionaryWithObjectsAndKeys: 
																							query																, @"query",
																						receiver															, @"receiver",
																						NSStringFromSelector(selector)				, @"selector",         																					
																						database															, @"database",
																						nil];
	
		[self performSelectorInBackground:@selector(executeInBackground:) withObject: arguments];	
		return YES;
	}
	@catch(NSException *e){
		NSLog(@"executeInBackground exception: %@", e.description);
		return NO;
	}
}


- (void) executeInBackground: (NSDictionary*) arguments{     
	if ([self isProcessing]) 
		return;			                		  					
	cancelQuery = NO; 
		
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
		         
	NSString *query = [arguments objectForKey: @"query"];
	NSString *database = [arguments objectForKey: @"database"];
	id receiver = [arguments objectForKey: @"receiver"];
	SEL selector = NSSelectorFromString([arguments objectForKey: @"selector"]); 
  QueryResult *result = [self execute: query withDefaultDatabase: database];		
	if (!cancelQuery)
		[receiver performSelectorOnMainThread: selector withObject: result waitUntilDone: YES];		

	[pool release];
}
                                                                                                                               
- (QueryResult*) execute: (NSString*) query withDefaultDatabase: (NSString*) database{
	return [self execute: query withDefaultDatabase: database logOutOnException: YES];
}                                                                                                                              

- (QueryResult*) execute: (NSString*) query withDefaultDatabase: (NSString*) database logOutOnException: (bool)logOutOnException{
	if ([self isProcessing]) 
		return nil;			        	
			
	QueryResult *result = [[QueryResult alloc] init];
	queryResult = result;		
	@try{                                       
		[TdsConnection activate: self];
		NSDate *timerStart = [NSDate date];
		[self setIsProcessing: TRUE]; 
		[self checkConnection];
		[self useDatabase: database]; 		
		[self executeQueries: query];
		[queryResult setQueryTime: [NSNumber numberWithDouble: -[timerStart timeIntervalSinceNow]]];
		[queryResult addCompletedMessage];	
		[queryResult setDatabase: [self currentDatabase]];
	}
	@catch (NSException *exception) {                                                                           
		if (logOutOnException)
		  [self logout];
		[self logMessage: [NSString stringWithFormat:@"%@", [exception reason]] error: YES];
	} 
	@finally{
		[TdsConnection deactivate: self];
		[self setIsProcessing: FALSE];		
	}   
	queryResult = nil; 
	[result autorelease];
	return result;
} 
 
-(QueryResult*) execute: (NSString*) query{  
	return [self execute: query withDefaultDatabase: nil];		
}

- (void) setCancelQuery{
	cancelQuery = YES;
}

- (void) logout{
	if (dbproc){
		NSLog(@"[%@ logout]", [self class]);
		dbclose(dbproc);			
		dbexit();	      
		dbproc = nil;
	}
}

- (void) dealloc{    
	NSLog(@"[%@ dealloc] connectionName: %@", [self class], [self connectionName]);
	[self logout]; 
	[queryResult release];
	[server release];
	[user release];
	[password release];	
	[connectionDefaults release];
	[super dealloc];
}

- (void) logMessage: (NSString*) message error: (BOOL) isError{
	if (queryResult){
		[queryResult addMessage: message];         
		if (isError){
			[queryResult setHasErrors: YES];
		}
	}
}

- (id) initWithServer: (NSString*) s 
								 user: (NSString*) u 
						 password: (NSString*) p
	 connectionDefaults: (NSString*) d
{	
	self = [super init];
	
	if(self){
		server = [[NSString alloc] initWithString: s];
		user = [[NSString alloc] initWithString: u];
		password = [[NSString alloc] initWithString: p];		
		connectionDefaults = [[NSString alloc] initWithString: d];
	}
	
	return self;
}    

- (TdsConnection*) clone{
	return [[[TdsConnection alloc] initWithServer: server user: user password: password connectionDefaults: connectionDefaults] autorelease];
}

-(NSString*) connectionName{
	return [NSString stringWithFormat: @"%@@%@", user, server];
}

-(NSString*) currentDatabase{                            
	if (!dbproc)
		return nil;
				
	@try{	                                                 		                                 		
		return [[NSString alloc] initWithUTF8String: dbname(dbproc)];
	}
	@catch(NSException *e){
		NSLog(@"currentDatabase exception: %@", e.description);
		return nil;
	}
}

@end
