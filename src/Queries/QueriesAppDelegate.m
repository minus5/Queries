#import "QueriesAppDelegate.h"

@implementation QueriesAppDelegate

@synthesize window;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {	
	connections = [[NSMutableArray	array] retain];
	[self newDocument: nil];
}

- (IBAction) newDocument: (id) sender{
	ConnectionController *connectionController = [[ConnectionController alloc] init];
	//NSLog(@"controller retainCount 1 %d", [connectionController retainCount]);	
	[connections addObject: connectionController];	
	[connectionController release];               
	//NSLog(@"controller retainCount 2 %d", [connectionController retainCount]);
	[connectionController showWindow: nil];	                      	                                                              
	//NSLog(@"controller retainCount 3 %d", [connectionController retainCount]);
} 
   
- (void) connectionWindowClosed:(ConnectionController *)controller
{                	
	//NSLog(@"[%@ connectionWindowClosed:%@] retainCount %d", [self class], controller, [controller retainCount]);	
	[connections removeObject: controller];    
	//NSLog(@"connections count: %d", [connections count]);
	//NSLog(@"[%@ connectionWindowClosed:%@] retainCount %d", [self class], controller, [controller retainCount]);
}
                                                                                      
- (int) numberOfEditedQueries{
	int count = 0;         
	for(ConnectionController *connectionController in connections){
		count += [connectionController numberOfEditedQueries];
	}                             
	return count;
}

- (NSApplicationTerminateReply) applicationShouldTerminate:(NSApplication *) sender{  			        
	int numberOfEditedQuries = [self numberOfEditedQueries];
	if (numberOfEditedQuries > 0){                         
		NSString *message = @"You have unsaved query. Quit anyway?";
		if (numberOfEditedQuries > 1){                                                                                       
			message = [NSString stringWithFormat: @"You have %d unsaved queries. Quit anyway?", numberOfEditedQuries];         
		}   										
		NSAlert *alert = [NSAlert alertWithMessageText: message
			defaultButton: @"Quit"
			alternateButton: @"Don't Quit"
      otherButton: nil								
      informativeTextWithFormat: @"Your changes will be lost if you don't save them."];		

		if ([alert runModal] == NSAlertAlternateReturn){   
			return NSTerminateCancel;		                     
		}
	}	
	return NSTerminateNow;
}

- (void)applicationWillTerminate:(NSNotification *)aNotification{ 
	[connections removeAllObjects];
	[connections release];
	[ConnectionsManager releaseSharedInstance];
}

- (IBAction) userPreferences: (id) sender{
	if (!preferences){
		preferences = [[PreferencesController alloc] init];
	}                                                    
	[preferences showWindow: self];
}                                          

- (void) dealloc{
	[preferences release];
	//[connections release];
	[super dealloc];
}                                

#pragma mark ---- register factory defaults ----

+(void) initialize{
	NSMutableDictionary *defaultValues = [NSMutableDictionary dictionary];   					
	//[defaultValues setObject:[QueriesAppDelegate connectionDefaults] forKey:	QueriesConnectionDefaults];
	[defaultValues setObject:[NSNumber numberWithInteger: 15] forKey:	QueriesLoginTimeout];
	[defaultValues setObject:[NSNumber numberWithInteger: 0] forKey:	QueriesQueryTimeout];	
	[defaultValues setObject:[NSNumber numberWithBool: NO] forKey:	QueriesGroupBySchema];
	[[NSUserDefaults standardUserDefaults] registerDefaults: defaultValues];
} 

@end
