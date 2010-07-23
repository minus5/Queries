#import <Cocoa/Cocoa.h>
@class ConnectionController;
@class TdsConnection;

@interface CredentialsController : NSWindowController {
	
	IBOutlet NSComboBox *serverCombo;
	IBOutlet NSComboBox *userCombo;
	IBOutlet NSSecureTextField *passwordText;
	
	NSMutableArray *credentials;    
  NSString *currentDatabase;  

}                             

@property (copy) NSString *currentDatabase;

+(CredentialsController*) controller;

- (IBAction) close: (id)sender;   
- (IBAction) connect: (id)sender;       
         
- (void) readCredentials;
- (void) writeCredentials;                                 
- (void) fillServerCombo;
- (IBAction) onServerSelected:(id) sender;
- (IBAction) onUserSelected:(id) sender;

- (NSString*) user;
- (NSString*) server;
- (NSString*) password; 

+ (NSString*) credentialsFileName;
+ (void) updateCredentialsWithServer: (NSString*) server 
  user: (NSString*) user
  password: (NSString*) password
  database: (NSString*) database;

@end
