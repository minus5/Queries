#import "QueriesAppDelegate.h"

@implementation QueriesAppDelegate

@synthesize window;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {	
	[self newDocument: nil];
}

- (IBAction) newDocument: (id) sender{
	ConnectionController *connectionController = [[ConnectionController alloc] init];
	[connectionController showWindow: nil];	
} 

@end
