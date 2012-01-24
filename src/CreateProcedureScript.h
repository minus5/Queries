#import <Cocoa/Cocoa.h>

#import "ColumnMetadata.h"
#import "QueryResult.h"
#import "TdsConnection.h"

@interface CreateProcedureScript : NSObject {
	NSString *database;
	NSString *object;
	NSString *type;
	TdsConnection *connection;
	id receiver;
	SEL selector;
}

- (id) initWithConnection: (TdsConnection*) connection
								 database: (NSString*) database 
									 object: (NSString*) object			
										 type: (NSString*) type
								 receiver: (id) receiver
								 selector: (SEL) selector;

- (void) generate;
- (void) setResult: (QueryResult*) result;

@end
