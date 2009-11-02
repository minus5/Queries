#import "QueryResult.h"

@implementation QueryResult

@synthesize messages, results, currentResultIndex;

- (id) init{
	results = [NSMutableArray array];
	[results retain];
	messages = [NSMutableArray array];
	[messages retain];
	return [super init];
}

- (void) dealloc{
	[results release];
	[messages release];
	[super dealloc];
}
- (void) addResultWithColumnNames: (NSArray*) columnNames andRows: rows{
	if ([columnNames count] == 0 && [rows count] == 0){
		return;
	}                                    
	// NSArray *newObject = [NSArray arrayWithObjects: columnNames, rows, nil];
	// if (!results){
	// 	results = [NSArray arrayWithObject: newObject];
	// }else{
	// 	results = [results arrayByAddingObject: newObject];
	// 	[results retain];	
	// }
	[results addObject: [NSArray arrayWithObjects: columnNames, rows, nil]];					
	[columnNames retain];
	[rows retain];
}               

- (void) addMessage: (NSString*) message{
	// if (!messages){
	// 	messages = [NSArray arrayWithObject: message];
	// }else{
	// 	messages = [results arrayByAddingObject: message];		
	// }                                                   
	// [messages retain];	
	
	[messages addObject: message];		
}

- (void) addCompletedMessage{
	if ([messages count] == 0 || [results count] == 0){
		[self addMessage: @"Command(s) completed successfully."];
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

@end
