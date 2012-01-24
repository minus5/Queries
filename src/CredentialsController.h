#import <Cocoa/Cocoa.h>
#include <CoreFoundation/CoreFoundation.h>
#include <Security/Security.h>
#include <CoreServices/CoreServices.h>

@class ConnectionController;
@class TdsConnection;

@interface CredentialsController : NSWindowController {
	
	IBOutlet NSComboBox *serverCombo;
	IBOutlet NSComboBox *userCombo;
	IBOutlet NSSecureTextField *passwordText;
	
	NSMutableArray *credentials;    
  NSString *currentDatabase;  

}                             

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
- (NSString*) database; 
- (NSDictionary*) credentials;
	
+ (NSString*) credentialsFileName;
+ (void) updateCredentialsWithServer: (NSString*) server 
																user: (NSString*) user
														password: (NSString*) password
														database: (NSString*) database;

- (void) setCurrentDatabase: (NSString*) db;
- (NSString *)getPasswordForAccount:(NSString *)account;
+ (BOOL) savePassword: (NSString *) password forAccount: (NSString*) account;

@end
