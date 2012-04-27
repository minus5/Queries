#import "CredentialsController.h"
#include <CoreFoundation/CoreFoundation.h>
#include <Security/Security.h>
#include <CoreServices/CoreServices.h>

@implementation CredentialsController

- (NSString*) windowNibName{
	return @"CredentialsView";
}
                                    
+ (NSString*) credentialsFileName{  
  NSArray* librarySearchPaths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES); 
	NSString* applicationSupportDirectory = [NSString stringWithFormat: @"%@/Queries", [librarySearchPaths objectAtIndex: 0]];
	if (![[NSFileManager defaultManager] fileExistsAtPath: applicationSupportDirectory]){
		[[NSFileManager defaultManager] 
			createDirectoryAtPath: applicationSupportDirectory
			withIntermediateDirectories: NO
								 attributes:nil 
											error: nil];
	}
	return [NSString stringWithFormat: @"%@/Credentials.plist", applicationSupportDirectory];
}

- (void) readCredentials{
	[credentials release];   			
	credentials = [NSMutableArray arrayWithContentsOfFile: [CredentialsController credentialsFileName]];
	if (!credentials)
		credentials = [NSMutableArray array];
	[credentials retain];
}                         

- (void) writeCredentials{    
  [CredentialsController updateCredentialsWithServer: [serverCombo stringValue] 
																								user: [userCombo stringValue]
																						password: [passwordText stringValue]
																						database: currentDatabase];
}    

+ (void) updateCredentialsWithServer: (NSString*) server 
																user: (NSString*) user
														password: (NSString*) password
														database: (NSString*) database{
  @try{
    if (server == NULL || user == NULL || database == NULL)
      return;
    
		NSString *account = [NSString stringWithFormat: @"%@@%@", user, server];
		[CredentialsController savePassword: password forAccount: account];
		      
    NSMutableArray* credentials = [NSMutableArray arrayWithContentsOfFile: [CredentialsController credentialsFileName]];
    if (credentials == NULL)
      credentials = [[NSMutableArray alloc] init];
 
    int indexToRemove = -1;
    for(id credential in credentials){              
    	NSString *s = [credential objectAtIndex: 0];
    	NSString *u = [credential objectAtIndex: 1];
    	if ([server isEqualToString:s] && [user isEqualToString:u]){
    		indexToRemove = [credentials indexOfObject: credential];  
    		if (!database && [credential count] > 3){
					database = [credential objectAtIndex: 3]; 
				}
    	}
    }                   	
    if (indexToRemove >= 0)
    	[credentials removeObjectAtIndex: indexToRemove];		

    [credentials insertObject: [NSArray arrayWithObjects: server, user, account, database, nil] atIndex: 0];		
    BOOL ret = [credentials writeToFile: [CredentialsController credentialsFileName] atomically: YES];     
		
		NSLog(@"updating credentials server: %@ user: %@ database: %@ ok?: %d", server, user, database, ret);
  }
	@catch (NSException *e) { 
	  NSLog(@"exception %@", e);                                                                           
	}  
}
                                   
- (void) fillServerCombo{		
	if ([credentials count] == 0)
		return;
	
	NSMutableArray *servers = [NSMutableArray array];	
	for(id credential in credentials){              
		NSString *serverName = [credential objectAtIndex: 0];
		if ([servers indexOfObjectIdenticalTo:serverName] == NSNotFound)
			[servers addObject: serverName];
	}  
	
	[serverCombo removeAllItems];   
	if ([servers count] > 0){
		[serverCombo addItemsWithObjectValues: servers];
		[serverCombo selectItemAtIndex: 0];
	}
	[self onServerSelected:nil];
}                                                                                     

- (IBAction) onServerSelected:(id) sender{
	if ([credentials count] == 0)
		return;

	NSString *selectedServer = [serverCombo stringValue];
	
	NSMutableArray *users = [NSMutableArray array];
	for(id credential in credentials){              
		NSString *serverName = [credential objectAtIndex: 0];
		NSString *user = [credential objectAtIndex: 1];
		if ([selectedServer isEqualToString:serverName])
			[users addObject: user];
	}
	
	[userCombo removeAllItems];	
	if ([users count] > 0){
		[userCombo addItemsWithObjectValues: users];
		[userCombo selectItemWithObjectValue: [users objectAtIndex: 0]];
	}
	[self onUserSelected: nil];	
}  

- (IBAction) onUserSelected:(id) sender{ 
	if ([credentials count] == 0)
		return;

	NSString *selectedServer = [serverCombo stringValue];
	NSString *selectedUser = [userCombo stringValue];
	
	for(id credential in credentials){              
		NSString *serverName = [credential objectAtIndex: 0];
		NSString *user = [credential objectAtIndex: 1];
		if ([selectedServer isEqualToString:serverName] && [selectedUser isEqualToString:user]){
			
			NSString *account = [NSString stringWithFormat: @"%@@%@", user, serverName];			
			[passwordText setStringValue: [self getPasswordForAccount: account]]; 
			//[passwordText setStringValue: [credential objectAtIndex:2]]; 

			NSString *db = @"master";
			if ([credential count] > 3)
				db = [credential objectAtIndex: 3];
			[currentDatabase release];
			currentDatabase = [db retain];
			
			return;
		}
	}	
}

- (void) dealloc{
	[super dealloc];
	[credentials release];
}

+(CredentialsController*) controller{	
	CredentialsController *controller = [[[CredentialsController alloc] init] autorelease];
 	[controller window];  
 	
 	[controller readCredentials]; 
  [controller fillServerCombo]; 
 		
 	return controller;
} 
    
- (NSString*) user{
	return [NSString stringWithString: [userCombo stringValue]];
}

- (NSString*) server{
	return [NSString stringWithString: [serverCombo stringValue]];
}

- (NSString*) password{
	return [NSString stringWithString: [passwordText stringValue]];
}       

- (NSString*) database{
	return currentDatabase;
}

- (NSDictionary*) credentials{
	return [NSDictionary dictionaryWithObjectsAndKeys: 
											 [self server], @"server", 		
											 [self user], @"user",
											 [self password], @"password",
											 nil]; 
}
                                
- (IBAction) connect: (id)sender{ 
	[[self window] orderOut: self];   
	[NSApp endSheet: [self window] returnCode: NSRunContinuesResponse]; 	  
} 

- (IBAction) close: (id)sender{ 
	[[self window] orderOut: self];  
  [currentDatabase release];                
	[NSApp endSheet: [self window] returnCode: NSRunAbortedResponse];
}   

- (void) setCurrentDatabase: (NSString*) db{
	if (!db)
		return;
	if ([db isEqualToString: currentDatabase])
		return;
	[currentDatabase release];
	currentDatabase = [db retain];
	[self writeCredentials];
}

//keyring
+ (BOOL) savePassword: (NSString *) password forAccount: (NSString*) account{
	OSStatus status;
	SecKeychainItemRef itemRef = nil;
	status = SecKeychainFindGenericPassword(
																					NULL,						
																					7,      
																					"Queries",
																					strlen([account UTF8String]),	
																					[account UTF8String],			
																					NULL,			
																					NULL,				
																					&itemRef					
																					);
	if(status == errSecSuccess){
		status = SecKeychainItemModifyAttributesAndData (
																										 itemRef,         
																										 NULL,            
																										 strlen([password UTF8String]),  
																										 [password UTF8String]         
																										 );
	}else{
		status = SecKeychainAddGenericPassword (
																						NULL,															
																						7,																
																						"Queries",												
																						strlen([account UTF8String]),			
																						[account UTF8String],							
																						strlen([password UTF8String]),		
																						[password UTF8String],						
																						NULL
																						);
	}
	if (itemRef) CFRelease(itemRef);
	NSLog(@"savePassword forAccount %@ status: %d", account, status);
  return status == errSecSuccess;
}

- (NSString *)getPasswordForAccount:(NSString *)account
{
	OSStatus status;
	
	void *passwordData;
	UInt32 passwordLength;
	SecKeychainItemRef itemRef;
	NSString *password = @"";

	if (!account) account = @"";

	status = SecKeychainFindGenericPassword(
																					NULL,						
																					7,      
																					"Queries",
																					strlen([account UTF8String]),	
																					[account UTF8String],			
																					&passwordLength,			
																					&passwordData,				
																					&itemRef					
																					);

	NSLog(@"gotPassword forAccount %@ status: %d", account, status);

	if (status == noErr) {
		// Create a \0 terminated cString out of passwordData
		char passwordBuf[passwordLength + 1];
		strncpy(passwordBuf, passwordData, (size_t)passwordLength);
		passwordBuf[passwordLength] = '\0';

		password = [NSString stringWithCString:passwordBuf encoding:NSUTF8StringEncoding];

		// Free the data allocated by SecKeychainFindGenericPassword:
		SecKeychainItemFreeContent(
															 NULL,           // No attribute data to release
															 passwordData    // Release data
															 );
	}

	return password;
}


@end
								
