#import "QueriesAppDelegate.h"

@implementation QueriesAppDelegate

@synthesize window;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {	
	NSLog(@"applicationDidFinishLaunching");
	connections = [[NSMutableArray	array] retain];
	[self newDocument: nil];
}

- (IBAction) newDocument: (id) sender{
	ConnectionController *connectionController = [[ConnectionController alloc] init];
	[connections addObject: connectionController];	
	[connectionController release];               
	[connectionController showWindow: nil];	                      	                                                              
	if (fileToOpenOnLaunch){
		[connectionController openFile: fileToOpenOnLaunch];
		[fileToOpenOnLaunch release];
		fileToOpenOnLaunch = nil;
	}
}
   
- (void) connectionWindowClosed:(ConnectionController *)controller
{                	
	[connections removeObject: controller];    
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
	[super dealloc];
}      

- (BOOL)application:(NSApplication *)theApplication openFile:(NSString *)filename{  
	NSLog(@"application openFile");
	id controller = [self controllerToOpenFile];
	if (controller)
		[controller openFile: filename];
	else
		fileToOpenOnLaunch = [filename retain];
	return YES;
}     

- (id) controllerToOpenFile{
	if (!connections)
		return nil;

	id controller = [[NSApp keyWindow] windowController];

	if (controller)
		if ([controller respondsToSelector: @selector(openFile:)])
			return controller;
	
	if ([connections count] == 0)
		[self newDocument: nil];

	return [connections objectAtIndex: [connections count] - 1];
}
                     
#pragma mark ---- register factory defaults ----

+(void) initialize{
	NSMutableDictionary *defaultValues = [NSMutableDictionary dictionary];   					
	[defaultValues setObject:[NSNumber numberWithInteger: 15] forKey:	QueriesLoginTimeout];
	[defaultValues setObject:[NSNumber numberWithInteger: 0] forKey:	QueriesQueryTimeout];	
	[defaultValues setObject:[NSNumber numberWithBool: NO] forKey:	QueriesGroupBySchema];
	[[NSUserDefaults standardUserDefaults] registerDefaults: defaultValues];
} 

@end
