#import "QueryResult.h"

@implementation QueryResult

@synthesize messages, results, currentResultIndex, database, hasErrors;

- (id) init{
	results = [NSMutableArray array];
	[results retain];
	messages = [NSMutableArray array];
	[messages retain];                                                  
	hasErrors = NO;
	return [super init];
}

- (void) dealloc{
	NSLog(@"QueryResult dealloc");
	[results release];
	[messages release];
	[super dealloc];
}
- (void) addResultWithColumnNames: (NSArray*) columnNames andRows: rows{
	if ([columnNames count] == 0 && [rows count] == 0){
		return;
	}                                    
	[results addObject: [NSArray arrayWithObjects: columnNames, rows, nil]];					
	[columnNames retain];
	[rows retain];
}               

- (void) addMessage: (NSString*) message{
	[messages addObject: message];		
}

- (void) addCompletedMessage{                       
	if (([messages count] == 0 || [results count] == 0) && (!hasErrors)){
		[self addMessage: @"Command(s) completed successfully.\n"];
	}	
}

-(BOOL) nextResult{
	if (currentResultIndex < [results count] - 1){		
		currentResultIndex++;
		return YES;
	}
	return NO;
}

-(BOOL) previousResult{
	if(currentResultIndex > 0){
		currentResultIndex--;
		return YES;
	}
	return NO;
}

-(int) resultsCount{
	return [results count];
}

-(BOOL) hasNextResults{
	return [self hasResults] && currentResultIndex < [results count] - 1;
}

-(BOOL) hasPreviosResults{
	return [self hasResults] && currentResultIndex > 0;
}

-(NSArray*) columns{
	if ([self hasResults]){
		return [[results objectAtIndex:currentResultIndex] objectAtIndex: 0];
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

- (NSString*) valueAtResult:(int) resultIndex row:(int) rowIndex column:(int) columnIndex{      
  @try {
		return [[[self resultAtIndex: resultIndex] objectAtIndex: rowIndex] objectAtIndex: columnIndex];
	}
	@catch (NSException *e) {
		return nil;
	}
}         
 
- (NSArray*) valuesInFirstColumn{
	NSMutableArray *values = [NSMutableArray array];
	for(NSArray *row in [self rows]){     
		[values addObject: [row objectAtIndex: 0]];
	}                   
	return values;            
}

- (NSArray*) resultAtIndex:(int) resultIndex{
	@try {
		return [[results objectAtIndex: resultIndex] objectAtIndex: 1];
	}
	@catch (NSException *e) {
		return nil;
	}
}	

- (NSArray*) columnsAtIndex:(int) resultIndex{
	@try {
		return [[results objectAtIndex: resultIndex] objectAtIndex: 0];
	}
	@catch (NSException *e) {
		return nil;
	}
}	


-(BOOL) hasResults{
	return [results count] > 0;
}

-(NSArray*) rows{
	if ([self hasResults]){
		return [[results objectAtIndex:currentResultIndex] objectAtIndex: 1];
	}
	else {
		return nil;
	}
}

-(NSString*) resultAsString{ 
	NSMutableString *r = [NSMutableString string];
	for(id row in [[results objectAtIndex:0] objectAtIndex: 1]){		
		[r appendFormat: @"%@", [row objectAtIndex:0]];
	}   
	return r;
}

- (NSArray*) resultWithFirstColumnNamed:(NSString*) columnName{
	for(id r in [self results]){
		if ([[[[r objectAtIndex: 0] objectAtIndex: 0] name] isEqualToString: columnName])
			return [r objectAtIndex: 1];
	}                               
	return nil;
}

- (NSString*) resultsInText{
	NSMutableString *resultString = [NSMutableString string];
	
	for(int resultIndex=0; resultIndex<[results count]; resultIndex++){
		NSArray *rows = [self resultAtIndex: resultIndex];
		NSArray *columns = [self columnsAtIndex: resultIndex]; 
		NSMutableString *sepeartor = [NSMutableString string];
 		//column names
		for(int c = 0; c < [columns count]; c++)
		{
			ColumnMetadata *column = [columns objectAtIndex: c];
			[resultString appendString: [[column name] stringByPaddingToLength: [column length] + 1 withString: @" " startingAtIndex: 0]];
			[sepeartor appendString: [@"" stringByPaddingToLength: [column length] withString: @"-" startingAtIndex: 0]];			
			[sepeartor appendString: @" "];
		}
		[resultString appendFormat: @"\n%@\n", sepeartor];
		//rows
		for(int r=0; r<[rows count]; r++){		
			for(int c=0; c<[columns count]; c++){
				NSString *value = [[rows objectAtIndex:r] objectAtIndex:c];
				ColumnMetadata *column = [columns objectAtIndex: c]; 
				[resultString appendString: [value stringByPaddingToLength: [column length] + 1 withString: @" " startingAtIndex: 0]];
			}                                                     
			[resultString appendFormat: @"\n"];
		}                         	  
		[resultString appendFormat: @"\n"];  
	}
	
	return resultString;
}

@end
