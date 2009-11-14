#import "ConnectionController.h"

@implementation ConnectionController

@synthesize outlineView, tdsConnection;

#pragma mark ---- init ----

- (NSString*) windowNibName{
	return @"ConnectionView";
}

- (void) windowDidLoad{
	[queryTabBar setCanCloseOnlyTab: YES];         
	//postoji neki problem u garbage collector environmentu kada ovo ukljucim
	//[queryTabBar setHideForSingleTab: YES];	
	[self createNewTab];
	[self changeConnection: nil];                 	
	[self goToQueryText: nil];  		
}     

- (void) dealloc{
	[databases release];
	[dbObjectsResults release];	
	[dbObjectsCache release];	  
	[tdsConnection logout];
	[tdsConnection release];
	[credentials release];
	[super dealloc];
}

#pragma mark ---- tabs ----

- (IBAction) newTab: (id) sender{
	[self createNewTab];
}  

- (QueryController*) createNewTab{
	QueryController *newQuerycontroller = [[QueryController alloc] initWithConnection: self];
	if (newQuerycontroller)
	{		
		NSTabViewItem *newTabViewItem = [[NSTabViewItem alloc] initWithIdentifier: newQuerycontroller];
		[newTabViewItem setView: [newQuerycontroller view]];	
		[queryTabs addTabViewItem:newTabViewItem];
		
		[newQuerycontroller addObserver: self forKeyPath: @"database" options: NSKeyValueObservingOptionNew context: nil];
		[newQuerycontroller addObserver: self forKeyPath: @"name" options: NSKeyValueObservingOptionNew context: nil];
		[queryTabs selectTabViewItem:newTabViewItem];
		[newQuerycontroller setName: [NSString stringWithFormat:@"Query %d", ++queryTabsCounter]];
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
	} 
	if ([keyPath isEqualToString: @"name"] && object == queryController){ 
		[[queryTabs selectedTabViewItem] setLabel: [queryController name]];
		[self displayDatabase];		
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

#pragma mark ---- close ----

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

- (void) shouldCloseCurrentQuery{     
	//TODO ovo je zasada jako gruba zabrana da ne moze zatvoriti prozor koji ima processing query
	if ([queryController isProcessing]){
		return;
	}
	
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

- (BOOL)tabView:(NSTabView *)aTabView shouldCloseTabViewItem:(NSTabViewItem *)tabViewItem
{
	[self shouldCloseCurrentQuery];
  return NO;
}

-(void) closeAlertEnded:(NSAlert *) alert code:(int) choice context:(void *) v{
	if (choice == NSAlertOtherReturn){
		return;
	}	
	if (choice == NSAlertDefaultReturn){
		if (![queryController saveQuery: NO]){ 
			return; 
		}
	}
	[self closeCurentQuery];
}    

#pragma mark ---- connection ----

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

#pragma mark ---- execute ----

-(IBAction) executeQuery: (id) sender{     
	if (!tdsConnection){                                                       			
		[self changeConnection: nil];
		return;		
	}      
	[queryController processingStarted];
	[self executeQueryInBackground: [queryController queryString] 
		withDatabase: [queryController database] 
		returnToObject: queryController 
		withSelector: @selector(setResult:)];
}                                 

- (void) executeQueryInBackground: (NSString*) query withDatabase: (NSString*) database returnToObject: (id) receiver withSelector: (SEL) selector{
	
	TdsConnection *conn = tdsConnection;		
	if ([conn isProcessing]){
		NSLog(@"creating temporary connection");
		conn = [tdsConnection clone];
		[conn login];		
	}
	
	if ([receiver respondsToSelector: @selector(setExecutingConnection:)]){          
		//[receiver performSelector: @selector(setExecutingConnection:) withObject: conn];
		[receiver setExecutingConnection: conn];
	}
		
  //pazi na ovu konstrukciju ako je database nil objekti nakon toga se nece dodati u dictionary, mora biti zadnji parametar
	NSDictionary *arguments = [NSDictionary dictionaryWithObjectsAndKeys: 
		[[NSString alloc] initWithString: query], @"query", 		
		receiver, @"receiver",
		NSStringFromSelector(selector), @"selector",         
    [NSNumber numberWithBool: !(conn == tdsConnection)] , @"logout",
		(database ? [[NSString alloc] initWithString: database] : nil), @"database", 
		nil];                                                                               	                                   
	                                                                                                  	
	[conn performSelectorInBackground:@selector(executeInBackground:) withObject: arguments];		
}

                              
#pragma mark ---- explain ----

-(IBAction) explain: (id) sender{                                  
	@try{			
		NSArray *rowData = [self selectedDbObject];
		NSArray *idParts = [[rowData objectAtIndex: 0] componentsSeparatedByString:@"."];
		NSString *databaseName = [idParts objectAtIndex: 0];
		NSString *objectType = [idParts objectAtIndex: 1];
		NSString *objectName = [rowData objectAtIndex: 2];		
		

		if ([objectType isEqualToString: @"tables"]){
		  [self createNewTab];  		                                           
			[queryController setString: [CreateTableScript scriptWithConnection: tdsConnection database: databaseName table: objectName]];
			[queryController setName: objectName];
			return;
		}					
		if ([objectType isEqualToString: @"procedures"] || [objectType isEqualToString: @"functions"] || [objectType isEqualToString: @"views"]){	
			QueryResult *queryResult = [tdsConnection execute: [NSString stringWithFormat: @"use %@\nexec sp_helptext '%@'", databaseName, objectName]];
			if (queryResult){
				[self createNewTab];
				[queryController setString:[queryResult resultAsString]];    
				[queryController setName: objectName];
			}
			return;
		}	       
		if ([objectType isEqualToString: @"users"]){
			[self createNewTab];                                       
			[queryController setString: [NSString stringWithFormat: @"use %@\nexec sp_helpuser '%@'\nexec sp_helprotect @username = '%@'", databaseName, objectName, objectName]];
			[queryController setName: objectName];
			[self executeQuery: nil];             
			[queryController showTextResults:nil];
			[queryController maximizeResults:nil];			                                                        
			return;
		}

	}
	@catch(NSException *e){
		NSLog(@"explain exception %@", e);
	} 
}

- (IBAction) openDocument:(id)sender{
	NSOpenPanel *panel = [NSOpenPanel openPanel];
	if ([panel runModal] == NSOKButton) {
		if ([queryController isEdited])
			[self createNewTab];
		[queryController openFile: [panel filename]];
	}
}       

#pragma mark ---- goto controll ----
    
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

- (IBAction) showHideDatabaseObjects: sender{
	float position = ([[[splitView subviews] objectAtIndex:0 ] frame].size.width == 0) ? 200 : 0;		
	[splitView setPosition: position ofDividerAtIndex:0];
}

@end
