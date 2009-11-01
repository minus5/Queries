#import <Cocoa/Cocoa.h>

@interface QueryResult : NSObject {
	NSMutableArray *messages;
	NSMutableArray *results;
	int currentResultIndex;
}

@property (readonly) NSArray *messages;
@property (readonly) NSArray *results;
@property (readonly) int currentResultIndex;

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
- (NSString*) resultAsString;

@end
