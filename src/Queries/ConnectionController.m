#import "ConnectionController.h"

@implementation ConnectionController

@synthesize outlineView;

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
		
		[newQuerycontroller addObserver: self forKeyPath: @"database" options: NSKeyValueObservingOptionNew context: nil];
		[queryTabs selectTabViewItem:newTabViewItem];
		
		
		// [self setQueryDatabaseToDefault]
		// if (tdsConnection){
		// 	[newQuerycontroller setDatabase: [tdsConnection currentDatabase]];
		// }
		
	}                              
	return newQuerycontroller;
}

- (void) observeValueForKeyPath: (NSString*) keyPath 
	ofObject: (id) object 
	change: (NSDictionary*) change 
	context: (void*) context
{
	if ([keyPath isEqualToString: @"database"] && object == queryController){ 
		[self displayDatabase];		
		//[self databaseChanged: nil];
	}
}

- (void)tabView:(NSTabView *)tabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem{
	queryController = [tabViewItem identifier];
	[self displayDatabase];
		        
	[self setNextResponder: queryController];	
	[queryController updateNextKeyViewRing];	
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
	if ([[queryTabs tabViewItems] count] == 0)
		[[self window] close];
}

- (void) shouldCloseCurrentQuery{
	if (![queryController isEdited]){
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
		if (![queryController saveQuery]){ 
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

- (void) didChangeConnection: (TdsConnection*) connection{
	tdsConnection = connection;
	[[self window] setTitle: [tdsConnection connectionName]];
	[self databaseChanged: nil];	
	[self dbObjectsFillSidebar];	
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
	[queryController setIsProcessing: YES];
	[self executeQueryInBackground: [queryController queryString] 
		withDatabase: [queryController database] 
		returnToObject: queryController 
		withSelector: @selector(setResult:)];
}                                 

- (void) executeQueryInBackground: (NSString*) query withDatabase: (NSString*) database returnToObject: (id) receiver withSelector: (SEL) selector{
  //pazi na ovu konstrukciju ako je database nil objekti nakon toga se nece dodati u dictionary, mora biti zadnji parametar
	NSDictionary *arguments = [NSDictionary dictionaryWithObjectsAndKeys: 
		[[NSString alloc] initWithString: query], @"query", 		
		receiver, @"receiver",
		NSStringFromSelector(selector), @"selector",         
		(database ? [[NSString alloc] initWithString: database] : nil), @"database", 
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
				[queryController setString: [NSString stringWithFormat: @"use %@\nexec sp_help '%@'", databaseName, fullName]];
				[self executeQuery: nil];
				[queryController nextResult: nil];
				//[queryController goToResults: nil];
			}else{
				QueryResult *queryResult = [tdsConnection execute: [NSString stringWithFormat: @"use %@\nexec sp_helpText '%@'", databaseName, fullName]];
				if (queryResult){
					[self createNewTab];
					[queryController setString:[queryResult resultAsString]];
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
	[queryController goToQueryText: [self window]];
}
                                        
- (IBAction) goToDatabaseObjects: (id) sender{
	[[self window] makeFirstResponder: outlineView];
}

- (IBAction) goToResults: (id) sender{
	[queryController goToResults: [self window]];
}

- (IBAction) goToMessages: (id) sender{
	[queryController goToMessages: [self window]];
}

@end
