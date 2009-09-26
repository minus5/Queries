#import "QueryExec.h"

@implementation QueryExec

QueryExec *active;
int msg_handler(DBPROCESS *dbproc, DBINT msgno, int msgstate, int severity, char *msgtext, char *srvname, char *procname, int line)
//-(int) msg_handler: (DBPROCESS *)dbproc: (DBINT) msgno: (int) msgstate: (int) severity: (char*) msgtext: (char*) srvname: (char*) procname: (int) line
{									
	enum {changed_database = 5701, changed_language = 5703 };	
	
	if (msgno == changed_database || msgno == changed_language) 
		return 0;
	
	NSMutableString *message = [NSMutableString stringWithCapacity:0];
	if (msgno > 0) {
		[message appendFormat: @"Msg %ld, Level %d, State %d\n", (long) msgno, severity, msgstate];
		
		if (strlen(srvname) > 0)
			[message appendFormat:@"Server '%s', ", srvname];
		if (strlen(procname) > 0)
			[message appendFormat:@"Procedure '%s', ", procname];
		if (line > 0)
			[message appendFormat:@"Line %d", line];		
	}	
	[message appendFormat:@"\n%s\n", msgtext];
	NSLog(@"%@", message);
	[active logMessage:message];
	
	if (severity > 10) {						
		[NSException raise:@"Exception" format: @"error: severity %d\n", severity];
	}
	
	return 0;							
}

int err_handler(DBPROCESS *dbproc, int severity, int dberr, int oserr, char *dberrstr, char *oserrstr)
{	
	NSMutableString *message = [NSMutableString stringWithCapacity:0];
	if (dberr) {							
		[message appendFormat:@"Msg %d, Level %d\n", dberr, severity];
		[message appendFormat:@"%s\n", dberrstr];
	}	
	else {
		[message appendFormat:@"DB-LIBRARY error:\n\t"];
		[message appendFormat:@"%s\n", dberrstr];
	}
	NSLog(@"%@", message);
	[active logMessage:message];
	
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
	RETCODE erc;
	
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
		
	if ([_databaseName cStringUsingEncoding:NSASCIIStringEncoding]  && (erc = dbuse(dbproc, [_databaseName cStringUsingEncoding:NSASCIIStringEncoding])) == FAIL) {
		[NSException raise:@"Exception" format: @"%d: unable to use to database %s\n", __LINE__, _databaseName];
	}				
	
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
	
	[results dealloc];
	results = [NSMutableArray array];
	
	while ((erc = dbresults(dbproc)) != NO_MORE_RESULTS) {
		
		struct COL *columns;		
		@try {
			NSArray *columnNames = [self readResultMetadata: &columns];
			NSArray *rows = [self readResultData: columns];
			[self readResultMessages];
			[results addObject: [NSArray arrayWithObjects: columnNames, rows, nil]];		
			[columnNames retain];
			[rows retain];
		}
		@catch (NSException *e) {
			@throw;
		}
		@finally {
			[self freeResultBuffers: columns];
		}																
	}	
	
	[results retain];
}

-(BOOL) execute: (NSString*) query{
			
	@try{	
		currentResult = 0;
		dbsettime(30);			
		[self executeQuery: query];		
		[self readResults];		
		return YES;
	}
	@catch (NSException *exception) {
		dbcancel(dbproc);
		dbcanquery(dbproc);
		[self logMessage: [NSString stringWithFormat:@"%@", [exception reason]]];
		return NO;
	}
}

-(void) nextResult{
	if (currentResult < [results count] - 1)
		currentResult++;
}

-(void) previousResult{
	if(currentResult > 0)
		currentResult--;
}

-(BOOL) hasResults{
	return [results count] > 0;
}

-(int) resultsCount{
	return [results count];
}

-(BOOL) hasNextResults{
	return [self hasResults] && currentResult < [results count] - 1;
}

-(BOOL) hasPreviosResults{
	return [self hasResults] && currentResult > 0;
}

-(NSArray*) columns{
	if ([self hasResults]){
		return [[results objectAtIndex:currentResult] objectAtIndex: 0];
	}
	else {
		return nil;
	}
}

-(NSArray*) rows{
	if ([self hasResults]){
		return [[results objectAtIndex:currentResult] objectAtIndex: 1];
	}
	else {
		return nil;
	}
}

-(int) rowsCount{
	if ([self hasResults]){
		return [[self rows] count];
	}
	else {
		return 0;
	} 
}

-(NSString*) rowValue: (int) rowIndex: (int) columnIndex{
	if ([self hasResults]){
		return [[[self rows] objectAtIndex:rowIndex] objectAtIndex: columnIndex]; 		
	}
	else {
		return nil;
	}
}


-(void) dealloc{
	dbclose(dbproc);
	dbexit();
	[super dealloc];
}


-(void) logMessage: (NSString*) message{
	if ([message length] > 5){
		[messages addObject: message];
	}
}

-(BOOL) hasMessages{
	return [messages count] > 0;
}

-(NSArray*) getMessages{
	return messages;
}

-(id) initWithCredentials: (NSString*) serverName 
	databaseName: (NSString*) databaseName 
			userName: (NSString*) userName 
			password: (NSString*) password
{
	self = [super init];
	
	if(self){
		messages = [[NSMutableArray	alloc] init];
		_serverName = [[NSString alloc] initWithString: serverName];
		_databaseName = [[NSString alloc] initWithString: databaseName];
		_userName = [[NSString alloc] initWithString:userName];
		_password = [[NSString alloc] initWithString: password];	
		active = self;
	}
	
	return self;
}

-(NSString*) connectionName{
	return [NSString stringWithFormat: @"%@@%@:%@", _userName, _serverName, _databaseName];
}

@end
