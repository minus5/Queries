#import "ConnectionController.h"

@implementation ConnectionController

- (NSString*) windowNibName{
	return @"ConnectionView";
}

- (void) windowDidLoad{
	[self newTab: nil];
	[self changeConnection: nil];                 
	[queryTabBar setCanCloseOnlyTab: YES];   
	//[queryTabBar setHideForSingleTab: YES];
}

- (IBAction) newTab: (id) sender{
	QueryController *newQuerycontroller = [[QueryController alloc] initWithConnection: self];
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
	[self shouldCloseCurrentQuery];
	return [[queryTabs tabViewItems] count] > 0 ? NO : YES;	
}                                                                  

- (void) closeCurentQuery{
	[queryTabs removeTabViewItem:[queryTabs selectedTabViewItem]];
	[self isEditedChanged: nil];
}

- (void) shouldCloseCurrentQuery{
	if (![[self currentQueryController] isEdited]){
		[self closeCurentQuery];
		return;                 		
	}                         
	
	NSString *message = [NSString stringWithFormat: @"Do you want to save the changes you made in document?" ];
	NSAlert *alert = [NSAlert alertWithMessageText: message
		defaultButton: @"Save"
		alternateButton: @"Don't Save"
		otherButton: @"Cancel"
     informativeTextWithFormat: @"Your changes will be lost if you don't save them."];

	[alert beginSheetModalForWindow: [self window]
		modalDelegate :self
		didEndSelector: @selector(closeAlertEnded:code:context:)
		contextInfo: NULL ];
}

-(void) closeAlertEnded:(NSAlert *) alert code:(int) choice context:(void *) v{
	if (choice == NSAlertOtherReturn){
		return;
	}	
	if (choice == NSAlertDefaultReturn){
		if (![[self currentQueryController] saveQuery]){ 
			return; 
		}
	}
	[self closeCurentQuery];
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

- (IBAction) openDocument:(id)sender {      
	[[self currentQueryController] openQuery];
}

- (int) numberOfEditedQueries {
	int count = 0;
	for(id item in [queryTabs tabViewItems]){
		if ([[item identifier] isEdited]){
			count++;
		}
	}           
	return count;
}                                                        

- (void) isEditedChanged: (id) sender{     
	[[self window] setDocumentEdited: [self numberOfEditedQueries] > 0];
}

@end
