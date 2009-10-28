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
		[newTabViewItem setLabel: [NSString stringWithFormat:@"Query: %d", ++queryTabsCounter]];
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
	[[self currentQueryController]	showResults: sender];
}

- (IBAction) showMessages: (id) sender{
	[[self currentQueryController ]	showMessages: sender];					
}

- (IBAction) changeConnection: (id) sender{
	if (!credentials){
		credentials = [CredentialsController controllerWithOwner: self];
		[credentials retain];
	}
	[credentials showSheet];
}

- (QueryController*) currentQueryController{
	return [[queryTabs selectedTabViewItem] identifier];
}

- (void) didChangeConnection: (TdsConnection*) connection{
	currentConnection = connection;
	[self dbObjectsFillSidebar];
	[[self window] setTitle: [currentConnection connectionName]];
	NSLog(@"didChangeConnection");
}

-(IBAction) indentSelection: (id)sender{
  [[self currentQueryController ] indentSelection: sender];
}

-(IBAction) unIndentSelection: (id)sender{
	[[self currentQueryController] unIndentSelection: sender];
}

- (IBAction) nextResult: (id) sender{
	[[self currentQueryController] nextResult:sender];
}

- (IBAction) previousResult: (id) sender{
	[[self currentQueryController] previousResult:sender];
}


-(IBAction) reloadDbObjects: (id) sender{
	[self dbObjectsFillSidebar];
}                                        

-(IBAction) executeQuery: (id) sender{
	NSString *queryString = [[self currentQueryController] queryString];
	[currentConnection execute: queryString];   
	[[self currentQueryController] setResults: [currentConnection results] andMessages: [currentConnection messages]];
}     


- (IBAction) saveDocument: (id) sender {
	[[self currentQueryController] saveQuery];
}

                          
/*
-(IBAction) explain: (id) sender{                         
	NSArray *rowData = [self selectedSidebarItem];  
	NSString *databaseName = [rowData objectAtIndex: 4];
	NSString *fullName = [rowData objectAtIndex: 3];
	NSString *objectType = [rowData objectAtIndex: 5];
	NSLog(@"class of objectType is: %@", [objectType class]);
	if (![objectType isEqualToString: @"NULL"]){
		if ([objectType isEqualToString: @"tables"]){
			[self newQuery: nil];
			[queryText setString: [NSString stringWithFormat: @"use %@\nexec sp_help '%@'", databaseName, fullName]];
			[self executeQuery: nil];
			[self nextResult: nil];
		}else{
			if ([currentConnection execute: [NSString stringWithFormat: @"use %@\nexec sp_helpText '%@'", databaseName, fullName]]){
				[self newQuery: nil]; 
				[queryText setString: [currentConnection resultAsString]];
			}
		}	
	}
}
 */

@end
