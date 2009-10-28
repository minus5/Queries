#import "ConnectionController.h"

@implementation ConnectionController

- (NSString*) windowNibName{
	return @"ConnectionView";
}

- (void) windowDidLoad{
	[self newTab: nil];
	[self changeConnection: nil]; 
}

- (IBAction) newTab: (id) sender{
	QueryController *newQuerycontroller = [[QueryController alloc] init];
	if (newQuerycontroller)
	{		
		NSTabViewItem *newTabViewItem = [[NSTabViewItem alloc] initWithIdentifier: newQuerycontroller];
		[newTabViewItem setLabel: [NSString stringWithFormat:@"TabItem: %d", ++queryTabsCounter]];
		[newTabViewItem setView: [newQuerycontroller view]];	
		[queryTabs addTabViewItem:newTabViewItem];
		[queryTabs selectTabViewItem:newTabViewItem];
	}	
}

- (IBAction) nextTab: (id) sender{
	[queryTabs selectNextTabViewItem:sender];
}

- (IBAction) previousTab: (id) sender{
	[queryTabs selectPreviousTabViewItem:sender];
}

- (BOOL) windowShouldClose: (id) sender{
	if ([[queryTabs tabViewItems] count] > 1){
		[queryTabs removeTabViewItem:[queryTabs selectedTabViewItem]];
		return NO;
	}
	else {
		return YES;
	}
}

- (IBAction) showResults: (id) sender{
	[[[queryTabs selectedTabViewItem] identifier]	showResults: sender];
}

- (IBAction) showMessages: (id) sender{
	[[[queryTabs selectedTabViewItem] identifier]	showMessages: sender];					
}

- (IBAction) changeConnection: (id) sender{
	if (!credentials){
		credentials = [CredentialsController controllerWithOwner: self];
		[credentials retain];
	}
	[credentials showSheet];
}

- (void) didChangeConnection: (id) newConnection{
	NSLog(@"didChangeConnection");
}


@end
