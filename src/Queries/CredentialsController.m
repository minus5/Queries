#import "CredentialsController.h"

@implementation CredentialsController

@synthesize currentDatabase;

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
	/*
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
	[credentials writeToFile: [CredentialsController credentialsFileName] atomically: YES];			
	*/
}     

+ (void) updateCredentialsWithServer: (NSString*) server 
  user: (NSString*) user
  password: (NSString*) password
  database: (NSString*) database{
    
  NSMutableArray* credentials = [NSMutableArray arrayWithContentsOfFile: [CredentialsController credentialsFileName]];
 
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
	
	[credentials insertObject: [NSArray arrayWithObjects: server, user, password, database, nil] atIndex: 0];		
	[credentials writeToFile: [CredentialsController credentialsFileName] atomically: YES]; 
  
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
			if ([credential count] > 3)
        [self setCurrentDatabase: (NSString*) [credential objectAtIndex: 3]];
      else 
        [self setCurrentDatabase: @"master"];
        //NSLog(@"current database: %@", [self currentDatabase]);
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

- (NSString*) database{
	return currentDatabase;
}
                                
- (IBAction) connect: (id)sender
{ 
	[[self window] orderOut: self];   
	[NSApp endSheet: [self window] returnCode: NSRunContinuesResponse]; 	  
} 

- (IBAction) close: (id)sender
{ 
	[[self window] orderOut: self];  
  [currentDatabase release];                
	[NSApp endSheet: [self window] returnCode: NSRunAbortedResponse];
}   

@end
								