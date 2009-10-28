#import <Cocoa/Cocoa.h>
#import "ConnectionController.h"
#import "TdsConnection.h"

@class ConnectionController;
@class TdsConnection;

@interface CredentialsController : NSWindowController {
	
	IBOutlet NSTextField *server;
	IBOutlet NSTextField *username;
	IBOutlet NSTextField *database;
	IBOutlet NSSecureTextField *password;

	ConnectionController *owner;
} 

+ (CredentialsController*) controllerWithOwner: (ConnectionController*) o;

- (void) showSheet;
- (IBAction) close: (id)sender;   
- (IBAction) connect: (id)sender;       
- (void) closeSheet;

@end
