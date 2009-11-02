#import "ConnectionController.h"

@implementation ConnectionController

- (NSString*) windowNibName{
	return @"ConnectionView";
}

- (void) windowDidLoad{
	[queryTabBar setCanCloseOnlyTab: YES];   
	[queryTabBar setHideForSingleTab: YES];	
	[self createNewTab];
	[self changeConnection: nil];                 	
	[self goToQueryText: nil];  		
}     

- (void) dealloc{
	[dbObjectsResults release];	
	[dbObjectsCache release];	  
	[tdsConnection logout];
	[tdsConnection release];
	[credentials release];
	[super dealloc];
}

- (IBAction) newTab: (id) sender{
	[self createNewTab];
}  

- (QueryController*) createNewTab{
	QueryController *newQuerycontroller = [[QueryController alloc] initWithConnection: self];
	if (newQuerycontroller)
	{		
		NSTabViewItem *newTabViewItem = [[NSTabViewItem alloc] initWithIdentifier: newQuerycontroller];
		[newTabViewItem setLabel: [NSString stringWithFormat:@"Query: %d", ++queryTabsCounter]];
		[newTabViewItem setView: [newQuerycontroller view]];	
		[queryTabs addTabViewItem:newTabViewItem];
		[queryTabs selectTabViewItem:newTabViewItem];
		                                         
		if (tdsConnection){
			[newQuerycontroller setDefaultDatabase: [tdsConnection currentDatabase]];
		}
	}                              
	return newQuerycontroller;
}  

- (void)tabView:(NSTabView *)tabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem{
	[self displayDefaultDatabase];                  
	[self setNextResponder: [tabViewItem identifier]];
	NSLog(@"nextResponder: %@", [self nextResponder]);
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

- (IBAction) changeConnection: (id) sender{
	if (!credentials){
		credentials = [CredentialsController controllerWithOwner: self];
		[credentials retain];
	}
	[credentials showSheet]; 	
}

//prebaci ovo u varijablu koju odrzavaj svakom promjenom taba
- (QueryController*) currentQueryController{
	return [[queryTabs selectedTabViewItem] identifier];
}

- (void) didChangeConnection: (TdsConnection*) connection{
	tdsConnection = connection;
	[[self window] setTitle: [tdsConnection connectionName]];
	[self dbObjectsFillSidebar];
	//[self databaseChanged: nil];	
	NSLog(@"didChangeConnection");
}

-(IBAction) reloadDbObjects: (id) sender{
	[self dbObjectsFillSidebar];
}                                        

-(IBAction) executeQuery: (id) sender{     
	if (!tdsConnection){                                                       			
		[self changeConnection: nil];
		return;		
	}
	QueryController *qc = [self currentQueryController];	  
	[qc setIsProcessing: YES];
	[self executeQueryInBackground: [qc queryString] withDatabase: [qc defaultDatabase] returnToObject: qc withSelector: @selector(setResult:)];
	
	// NSDictionary *arguments = [NSDictionary dictionaryWithObjectsAndKeys: 
	// 	[NSString stringWithFormat: @"%@", [qc queryString]], @"query", 
	// 	[NSString stringWithFormat: @"%@", [qc defaultDatabase]], @"database", 
	// 	qc, @"receiver",
	// 	NSStringFromSelector(@selector(setResult:)), @"selector",
	// 	nil];                                                                               	                                   
	//                                                                                                   	
	// [tdsConnection performSelectorInBackground:@selector(executeInBackground:) withObject: arguments];	
	//TODO pozovi ovo nakon sto query zavrsi, ali pazi ako promjeni tab
	//[self databaseChanged: nil];	
}                                 

- (void) executeQueryInBackground: (NSString*) query withDatabase: (NSString*) database returnToObject: (id) receiver withSelector: (SEL) selector{

	NSDictionary *arguments = [NSDictionary dictionaryWithObjectsAndKeys: 
		[NSString stringWithFormat: @"%@", query], @"query", 
		[NSString stringWithFormat: @"%@", database], @"database", 
		receiver, @"receiver",
		NSStringFromSelector(selector), @"selector",
		nil];                                                                               	                                   
	                                                                                                  	
	[tdsConnection performSelectorInBackground:@selector(executeInBackground:) withObject: arguments];		
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

-(IBAction) explain: (id) sender{                                  
	@try{			
		NSArray *rowData = [self selectedDbObject];
		NSString *databaseName = [rowData objectAtIndex: 4];
		NSString *fullName = [rowData objectAtIndex: 3];
		NSString *objectType = [rowData objectAtIndex: 5];
		
		if (![objectType isEqualToString: @"NULL"]){
			if ([objectType isEqualToString: @"tables"]){
			  [self createNewTab];  		                                           
				[[self currentQueryController] setString: [NSString stringWithFormat: @"use %@\nexec sp_help '%@'", databaseName, fullName]];
				[self executeQuery: nil];
				[[self currentQueryController] nextResult: nil];
				//[self goToResults: nil];
			}else{
				QueryResult *queryResult = [tdsConnection execute: [NSString stringWithFormat: @"use %@\nexec sp_helpText '%@'", databaseName, fullName]];
				if (queryResult){
					[self createNewTab];
					[[self currentQueryController] setString:[queryResult resultAsString]];
					//[self goToQueryText: nil];
				}
			}	
		}
	}
	@catch(NSException *e){
		NSLog(@"explain exception %@", e);
	} 
}       
    
- (IBAction) goToQueryText: (id) sender{
	[[self currentQueryController] goToQueryText: [self window]];
}
                                        
- (IBAction) goToDatabaseObjects: (id) sender{
	[[self window] makeFirstResponder: outlineView];
}

- (IBAction) goToResults: (id) sender{
	[[self currentQueryController] goToResults: [self window]];
}

- (IBAction) goToMessages: (id) sender{
	[[self currentQueryController] goToMessages: [self window]];
}

@end
