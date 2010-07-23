#import "TdsConnection.h"

@interface ConnectionsManager : NSObject
{                           
	NSMutableDictionary *pool;
}

- (TdsConnection*) connectionToServer: (NSString*) server  
  withUser: (NSString*) user 
  andPassword: (NSString*) password;
- (TdsConnection*) connectionWithName: (NSString*) connectionName;
- (int) connectionsCount: (NSString*) connectionName;
- (void) cleanup;

+ (ConnectionsManager*) sharedInstance;              
+ (void) releaseSharedInstance;  

+ (NSString*) sqlFileContent: (NSString*) queryFileName;

@end
