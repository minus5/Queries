#import <Cocoa/Cocoa.h>
#import "ConnectionController.h"
#import "TdsConnection.h" 


@class ConnectionController;
@class TdsConnection;

@interface CredentialsController : NSWindowController {
	
	IBOutlet NSComboBox *serverCombo;
	IBOutlet NSComboBox *userCombo;
	IBOutlet NSSecureTextField *passwordText;
	
	NSMutableArray *credentials;

	ConnectionController *owner;
} 

+ (CredentialsController*) controllerWithOwner: (ConnectionController*) o;

- (void) showSheet;
- (IBAction) close: (id)sender;   
- (IBAction) connect: (id)sender;       
- (void) closeSheet;            
         
- (void) readCredentials;
- (void) writeCredentials;                                 
- (void) fillServerCombo;
- (IBAction) onServerSelected:(id) sender;
- (IBAction) onUserSelected:(id) sender;

- (NSString*) user;
- (NSString*) server;
- (NSString*) password;

@end
