#import <Cocoa/Cocoa.h>
#import "ColumnMetadata.h"

@interface QueryResult : NSObject {
	NSMutableArray *messages;
	NSMutableArray *results;
	int currentResultIndex;
	NSString *database;              
	BOOL hasErrors;
}

@property (readonly) NSArray *messages;
@property (readonly) NSArray *results;
@property (readonly) int currentResultIndex;
@property (copy) NSString *database;
@property BOOL hasErrors;

- (void) addResultWithColumnNames: (NSArray*) columnNames andRows: rows;
- (void) addMessage: (NSString*) message;
- (void) addCompletedMessage;
- (int) resultsCount;
- (BOOL) nextResult;
- (BOOL) previousResult;
- (BOOL) hasResults;
- (BOOL) hasNextResults;
- (BOOL) hasPreviosResults;
- (NSArray*) columns;
- (NSArray*) rows;
- (int) rowsCount;
- (NSString*) rowValue: (int) rowIndex: (int) columnIndex;   
- (NSArray*) resultAtIndex:(int) resultIndex;
- (NSArray*) columnsAtIndex:(int) resultIndex;
- (NSString*) valueAtResult:(int) resultIndex row:(int) rowIndex column:(int) columnIndex;
- (NSString*) resultAsString;
- (NSArray*) valuesInFirstColumn;             
- (NSArray*) resultWithFirstColumnNamed:(NSString*) columnName;
- (NSString*) resultsInText;

@end
