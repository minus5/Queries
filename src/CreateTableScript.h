#import <Cocoa/Cocoa.h>

#import "ColumnMetadata.h"
#import "QueryResult.h"
#import "TdsConnection.h"

@interface CreateTableScript : NSObject {
	NSString *tableName;
	NSMutableString *script;
	QueryResult *result;	

	TdsConnection *connection;
	NSString *database;
	NSString *table;
	id receiver;
	SEL selector;
}
                 
- (id) initWithConnection: (TdsConnection*) connection
								 database: (NSString*) database 
										table: (NSString*) table			
								 receiver: (id) receiver
								 selector: (SEL) selector;

- (void) generate;
- (void) setResult: (QueryResult*) r;
- (void) columns;
- (void) column:(NSArray*) columnData;
- (void) identity:(NSString*) columnName;   
- (void) rowguid:(NSString*) columnName;
- (void) columnDefault:(NSString*) columnName;
- (void) columnCheck:(NSString*) columnName;
- (void) primaryKey;                    
- (void) foreignKeys;
- (void) indexes;
- (NSArray*) indexResults;
- (NSArray*) constraintResults;

@end                                
