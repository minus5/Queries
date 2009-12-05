#import "CredentialsController.h"

@implementation CredentialsController

- (NSString*) windowNibName{
	return @"CredentialsView";
}
                                    
- (NSString*) credentialsFileName{  
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
	credentials = [NSMutableArray arrayWithContentsOfFile: [self credentialsFileName]];
	if (!credentials)
		credentials = [NSMutableArray array];
	[credentials retain];
}                         

- (void) writeCredentials{    
	NSString *selectedServer = [serverCombo stringValue];
	NSString *selectedUser = [userCombo stringValue];
	                                         
	int indexToRemove = -1;
	for(id credential in credentials){              
		NSString *serverName = [credential objectAtIndex: 0];
		NSString *user = [credential objectAtIndex: 1];
		if ([selectedServer isEqualToString:serverName] && [selectedUser isEqualToString:user])
			indexToRemove = [credentials indexOfObject: credential];
	}                   	
	if (indexToRemove >= 0)
		[credentials removeObjectAtIndex: indexToRemove];		
	
	[credentials insertObject: [NSArray arrayWithObjects: selectedServer, selectedUser, [passwordText stringValue], nil] atIndex: 0];		
	[credentials writeToFile: [self credentialsFileName] atomically: YES];			
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
			[passwordText setStringValue: [credential objectAtIndex:2]];
			return;
		}
	}	
}

- (void) dealloc{
	[super dealloc];
	[credentials release];
}

+(CredentialsController*) controller{	
	CredentialsController *controller = [[CredentialsController alloc] init];
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

                                  
- (IBAction) connect: (id)sender
{ 
	[[self window] orderOut: self];   
	[NSApp endSheet: [self window] returnCode: NSRunContinuesResponse]; 	  
} 

- (IBAction) close: (id)sender
{ 
	[[self window] orderOut: self];                  
	[NSApp endSheet: [self window] returnCode: NSRunAbortedResponse];
}   

@end
								