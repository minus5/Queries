#import "PreferencesController.h"
#import "QueriesAppDelegate.h"

@implementation PreferencesController

-(id) init
{
	if (![super initWithWindowNibName: @"Preferences"]){
		return nil;
	}            
	return self;
}

- (void) windowDidLoad{
	[self readDefaults];
}

- (void) readDefaults{
	[connectionDefaults setString: [[NSUserDefaults standardUserDefaults] objectForKey: QueriesConnectionDefaults]];	
	[queryTimeout setIntValue: [[[NSUserDefaults standardUserDefaults] objectForKey: QueriesQueryTimeout] integerValue] ];
	[loginTimeout setIntValue: [[[NSUserDefaults standardUserDefaults] objectForKey: QueriesLoginTimeout] integerValue] ];
	[groupBySchema setState: [[[NSUserDefaults standardUserDefaults] objectForKey: QueriesGroupBySchema] boolValue] ];
} 

- (void) saveDefaults{
	[[NSUserDefaults standardUserDefaults] setObject: [connectionDefaults string] forKey: QueriesConnectionDefaults];	
	[[NSUserDefaults standardUserDefaults] setObject: [NSNumber numberWithInteger: [queryTimeout intValue]] forKey: QueriesQueryTimeout];	
	[[NSUserDefaults standardUserDefaults] setObject: [NSNumber numberWithInteger: [loginTimeout intValue]] forKey: QueriesLoginTimeout];		
	[[NSUserDefaults standardUserDefaults] setObject: [NSNumber numberWithBool: [groupBySchema state]] forKey: QueriesGroupBySchema];
}                                                                                                               

- (void) textDidChange: (NSNotification *) aNotification{
	[self saveDefaults];
}

- (void)controlTextDidChange:(NSNotification *)aNotification{
	[self saveDefaults];
}   

- (IBAction)checkboxClicked:(id)sender
{
	[self saveDefaults];
}
                                                        
- (IBAction) resetDefaults:(id)sender{ 
	[[NSUserDefaults standardUserDefaults] removeObjectForKey: QueriesConnectionDefaults]; 
	[[NSUserDefaults standardUserDefaults] removeObjectForKey: QueriesQueryTimeout];
	[[NSUserDefaults standardUserDefaults] removeObjectForKey: QueriesLoginTimeout];
	[[NSUserDefaults standardUserDefaults] removeObjectForKey: QueriesGroupBySchema];
	[self readDefaults];            
	}

@end