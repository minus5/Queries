#import "PreferencesController.h"
#import "QueriesAppDelegate.h"

NSString *const QueriesConnectionDefaults = @"ConnectionDefaults";

@implementation PreferencesController

-(id) init
{
	if (![super initWithWindowNibName: @"Preferences"]){
		return nil;
	}            
	return self;
}

- (void) windowDidLoad{
	[connectionDefaults setString: [[NSUserDefaults standardUserDefaults] objectForKey: QueriesConnectionDefaults]];
}                                                                                                                

- (void) textDidChange: (NSNotification *) aNotification{
	[[NSUserDefaults standardUserDefaults] setObject: [connectionDefaults string] forKey: QueriesConnectionDefaults];	
	NSLog(@"didChangeText");
}
                                                        
- (IBAction) restoreConnectionDefaults:(id)sender{  
	[connectionDefaults setString: [QueriesAppDelegate connectionDefaults]];
	[self textDidChange: nil];
}

@end