#import <Cocoa/Cocoa.h>

#import "ColumnMetadata.h"
#import "QueryResult.h"
#import "TdsConnection.h"

@interface CreateTableScript : NSObject {
	NSString *tableName;
	NSMutableString *script;
	QueryResult *result;	
}

@property (readonly, copy) NSString* script;
                 
+ (NSString*) scriptWithConnection: (TdsConnection*) connection  database:(NSString*) database table: (NSString*) table;
- (id) initWithConnection: (TdsConnection*) connection  database:(NSString*) database table: (NSString*) table;
- (void) columns;
- (void) column:(NSArray*) columnData;
- (void) identity:(NSString*) columnName;   
- (void) rowguid:(NSString*) columnName;
- (void) columnDefault:(NSString*) columnName;
- (void) columnCheck:(NSString*) columnName;
- (void) primaryKey;                    
- (void) foreignKeys;
- (void) indexes;

@end                                
