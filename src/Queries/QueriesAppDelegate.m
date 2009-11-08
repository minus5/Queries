#import "QueriesAppDelegate.h"

@implementation QueriesAppDelegate

@synthesize window;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {	
	connections = [NSMutableArray	array];
	[connections retain];
	[self newDocument: nil];
}

- (IBAction) newDocument: (id) sender{
	ConnectionController *connectionController = [[ConnectionController alloc] init];
	[connectionController showWindow: nil];	
	[connections addObject: connectionController];
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

+ (NSString*) sqlFileContent: (NSString*) queryFileName{
	NSString *query = [NSString stringWithContentsOfFile: 
		[[NSBundle mainBundle] pathForResource: queryFileName ofType:@"sql"]
		encoding: NSUTF8StringEncoding
		error: nil
		];
	return query;
}

@end
