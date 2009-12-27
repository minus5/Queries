#import "ConnectionController.h"

@implementation ConnectionController

@synthesize outlineView;

#pragma mark ---- init ----

- (NSString*) windowNibName{
	return @"ConnectionView";
}

- (void) windowDidLoad{
	[queryTabBar setCanCloseOnlyTab: YES];         
	[self createNewTab];
	[self changeConnection: nil];                 	
	[self goToQueryText: nil];                                                    
}     

- (void) dealloc{
	NSLog(@"[%@ dealloc]", [self class]);
	[databases release];
	[dbObjectsResults release];	
	[dbObjectsCache release];	  
	[connectionName release];
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
		[newQuerycontroller addObserver: self forKeyPath: @"status" options: NSKeyValueObservingOptionNew context: nil];
		[queryTabs selectTabViewItem:newTabViewItem];
		[newQuerycontroller setName: [NSString stringWithFormat:@"Query %d", ++queryTabsCounter]];
	}                              
	return newQuerycontroller;
}

- (void) displayStatus{
	[statusLabel setStringValue: [queryController status]];
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
	if ([keyPath isEqualToString: @"status"] && object == queryController){ 
		[self displayStatus];		
	}
}                      

- (void)tabView:(NSTabView *)tabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem{
	queryController = [tabViewItem identifier];
	[self displayDatabase];	 
	[self displayStatus];         
	[self setNextResponder: queryController];	
} 

- (IBAction) nextTab: (id) sender{
	[queryTabs selectNextTabViewItem:sender];	
}

- (IBAction) previousTab: (id) sender{
	[queryTabs selectPreviousTabViewItem:sender];
}

#pragma mark ---- close ---- 

- (BOOL) windowShouldClose: (id) sender{                        
	//NSLog(@"[%@ windowShouldClose:%@]", [self class], sender);  	
	[self shouldCloseCurrentQuery];
	return [[queryTabs tabViewItems] count] > 0 ? NO : YES;	
}                                                                  

- (void) windowWillClose:(NSNotification *)notification
{                	
	//NSLog(@"[%@ windowWillClose:] retainCount: %d", [self class], [self retainCount]);      
	[[NSApp delegate] performSelector:@selector(connectionWindowClosed:) withObject:self afterDelay:0.0];
	//NSLog(@"[%@ windowWillClose:] retainCount: %d", [self class], [self retainCount]);
}

- (void) closeCurentQuery{
	QueryController *controller = queryController;
	NSTabViewItem *tabViewItem = [queryTabs selectedTabViewItem];
	[queryTabs removeTabViewItem: tabViewItem];
	[self isEditedChanged: nil]; 	
	                                                                                                        		
	[controller removeObserver: self forKeyPath: @"database"];
	[controller removeObserver: self forKeyPath: @"name"];	
	[tabViewItem release];
	[controller release];                                                                                 
		
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
		credentials = [CredentialsController controller];
		[credentials retain];
	} 
	[NSApp beginSheet: [credentials window]
		modalForWindow: [self window]
		modalDelegate: self 
		didEndSelector: @selector(didChangeConnection:returnCode:contextInfo:)
		contextInfo:nil];	
} 

- (void) changeConnection:(NSAlert *) alert code:(int) choice context:(void *) v{
	[NSApp endSheet: [alert window]];
	[[alert window] orderOut: self];
	[self changeConnection: nil];
}                            

- (void) didChangeConnection:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo{
	if (returnCode != NSRunContinuesResponse)
		return;
                                                                            
	NSString *connectionDescription = [NSString stringWithFormat: @"%@ as %@", [credentials server], [credentials user]];
	ConnectingController *cc = [[ConnectingController alloc] initWithLabel: [NSString stringWithFormat: @"Connecting to %@ ...", connectionDescription]];
	BOOL retry = NO;
	
	@try{	
    [NSApp beginSheet: [cc window] modalForWindow: [self window] modalDelegate: nil didEndSelector: nil contextInfo:nil];		
		TdsConnection *newConnection = [[ConnectionsManager sharedInstance] connectionToServer: [credentials server] withUser: [credentials user] andPassword:[credentials password]];		
		[credentials writeCredentials];		
		[self didChangeConnection: newConnection];
	}
	@catch (NSException * e) {
		NSLog(@"connect error: %@", e);
		retry = YES;
	}
	@finally {      		
		[NSApp endSheet: [cc window]];
		[[cc window] orderOut: self];
  	[cc release];
	}	                 
	
	if (retry){
		NSAlert *alert = [NSAlert alertWithMessageText: [NSString stringWithFormat: @"Unable to connect to %@ !", connectionDescription]
			defaultButton: nil
			alternateButton: nil
			otherButton: nil
	    informativeTextWithFormat: @""];

		[alert beginSheetModalForWindow: [self window]
			modalDelegate :self
			didEndSelector: @selector(changeConnection:code:context:)
			contextInfo: NULL ];
	}      
}

- (void) didChangeConnection: (TdsConnection*) connection{
	[connectionName release];
	connectionName = [[connection connectionName] retain];

	[[self window] setTitle: [connection connectionName]];
	
	[self databaseChanged: nil];	
	[self dbObjectsFillSidebar];	
	//NSLog(@"didChangeConnection");
}              

- (TdsConnection*) tdsConnection{
	return [[ConnectionsManager sharedInstance] connectionWithName: connectionName];
}

-(IBAction) reloadDbObjects: (id) sender{
	[self dbObjectsFillSidebar];
}                                        

#pragma mark ---- execute ----

-(IBAction) executeQuery: (id) sender{     
	if (!connectionName){                                                       			
		[self changeConnection: nil];
		return;		
	}      
	[[self tdsConnection] executeInBackground: [queryController queryString] 
		withDatabase: [queryController database] 
		returnToObject: queryController 
		withSelector: @selector(setResult:)];
}                                 
                              
#pragma mark ---- explain ----

-(IBAction) explain: (id) sender{                                  
	@try{			
		NSArray *rowData = [self selectedDbObject];
		if (!rowData)
		  return;
			
		NSArray *idParts = [[rowData objectAtIndex: 0] componentsSeparatedByString:@"."];
		NSString *databaseName = [idParts objectAtIndex: 0];
		NSString *objectType = [idParts objectAtIndex: 1];
		NSString *objectName = [rowData objectAtIndex: 2];

		if ([objectType isEqualToString: @"tables"]){
		  [self createNewTab];  		                                           
			[queryController setString: [CreateTableScript scriptWithConnection: [self tdsConnection] database: databaseName table: objectName]];
			[queryController setName: objectName];
			return;
		}					
		if ([objectType isEqualToString: @"procedures"] || [objectType isEqualToString: @"functions"] || [objectType isEqualToString: @"views"]){	
			QueryResult *queryResult = [[self tdsConnection] execute: [NSString stringWithFormat: @"use %@\nexec sp_helptext '%@'", databaseName, objectName]];
			if (queryResult){
				//create to alter
				NSString *typeName =  [[objectType substringToIndex: [objectType length] - 1] uppercaseString];
				NSString *script = [queryResult resultAsString];                                                                             				
				NSString *createRegexString = [NSString stringWithFormat: @"(?im)(^\\s*CREATE\\s+%@\\s+)", typeName]; 
				NSString *alterRegexString = [NSString stringWithFormat: @"ALTER %@ ", typeName]; 
				script = [script stringByReplacingOccurrencesOfRegex:createRegexString withString:alterRegexString];                                        
				
				[self createNewTab];              								                                                                           
				[queryController setString: script];    
				[queryController setName: objectName];
			}
			return;
		}	       
		if ([objectType isEqualToString: @"users"]){
			[self createNewTab];                                       
			[queryController setString: [NSString stringWithFormat: @"use %@\nexec sp_helpuser '%@'\nexec sp_helprotect @username = '%@'", databaseName, objectName, objectName]];
			[queryController setName: objectName];
			[self executeQuery: nil];             
			[queryController showTextResults];
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

- (IBAction) goToDatabaseObjects: (id) sender{
	[[self window] makeFirstResponder: outlineView];
}
    
- (IBAction) goToQueryText: (id) sender{
	[queryController goToQueryText];
}
                                        
- (IBAction) goToResults: (id) sender{
	[queryController goToResults];
}

- (IBAction) goToTextResults: (id) sender{
	[queryController goToTextResults];
}

- (IBAction) goToMessages: (id) sender{
	[queryController goToMessages];
}

- (IBAction) showHideDatabaseObjects: sender{
	float position = ([[[splitView subviews] objectAtIndex:0 ] frame].size.width == 0) ? 200 : 0;		
	[splitView setPosition: position ofDividerAtIndex:0];
	if (position == 0)
		[self goToQueryText: nil];		
	else
		[self goToDatabaseObjects: nil];
} 
  
- (void) keyDown:(NSEvent *)theEvent{         
	//command-{}
	if ([theEvent keyCode] == 30 && [theEvent modifierFlags] == 1179914){	
		[self nextTab: nil];                                               
		return;
	}
	if ([theEvent keyCode] == 33 && [theEvent modifierFlags] == 1179914){
		[self previousTab: nil];		                                       
		return;
	}
			
	//NSLog(@"keyDown event keyCode %d modifierFlags: %d window %@", [theEvent keyCode], [theEvent modifierFlags], [theEvent window]);	
}               

- (void)doCommandBySelector:(SEL)aSelector
{                                               
	//NSLog(@"connection received doCommandBySelector event");	
  NSEvent* e = [NSApp currentEvent];
  if([e type] == NSKeyDown){
		[self keyDown:e];
  } else {
		[super doCommandBySelector:aSelector];
  } 
}    


#pragma mark ---- database objects sidebar ----

-(void) dbObjectsFillSidebar{         
	@try{	       
		[self fillDatabasesCombo];		
		[self readDatabaseObjects];	  
	}@catch(NSException *exception){    
		NSLog(@"error in fillSidebar: %@", exception);
	}
}                         

- (void) readDatabaseObjects{        
	[dbObjectsResults release];	
	dbObjectsResults = nil;
	[outlineView reloadData];
	[outlineView setDoubleAction: @selector(databaseObjectSelected)];
	[[self tdsConnection] executeInBackground: [self databaseObjectsQuery]
		withDatabase: @"master" 
		returnToObject: self
		withSelector: @selector(setObjectsResult:)];		
}                                                                 
                                               
- (NSString*) databaseObjectsQuery{
	NSMutableString *query = [NSMutableString stringWithString:[self queryFileContents: @"objects_start"]];
	[query appendFormat: @"\n\n"];
	for(id db in databases){
		[query appendFormat: @"begin try\nuse %@\n\n", db];
		[query appendFormat: @"%@\n", [self queryFileContents: @"objects_in_database"]];
		[query appendFormat: @"\nend try\nbegin catch\nend catch\n", db];
	} 	
	[query appendFormat: @"%@\n", [self queryFileContents: @"objects_end"]];
	return query;
}

- (NSString*) queryFileContents: (NSString*) queryFileName{
	NSString *query = [NSString stringWithContentsOfFile: 
		[[NSBundle mainBundle] pathForResource: queryFileName ofType:@"sql"]
		encoding: NSUTF8StringEncoding
		error: nil
		];
	return query;
}

- (void) setObjectsResult: (QueryResult*) queryResult{ 
	[dbObjectsResults release];	
	dbObjectsResults = [queryResult rows];	
	[dbObjectsResults retain];
	
	[dbObjectsCache release];		
	dbObjectsCache = [NSMutableDictionary dictionary];		
	[dbObjectsCache retain];             
	
	[outlineView reloadData];
	[outlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];	
}

- (void) fillDatabasesCombo{	     
	NSMutableArray *dbs = [NSMutableArray array];
	QueryResult *queryResult = [[self tdsConnection] execute: @"select name from master.sys.databases where state_desc = 'ONLINE' and (owner_sid != 01 or name = 'master') and isnull(has_dbaccess([Name]), 0) = 1 order by name"];	
	if (queryResult){         
		[databasesPopUp removeAllItems];
		for(NSArray *row in [queryResult rows]){     
			NSString *title = [row objectAtIndex: 0];
			[dbs addObject: title];
			[databasesPopUp addItemWithTitle: title];
		} 
		[databasesPopUp selectItemWithTitle: [[self tdsConnection] currentDatabase]];     
		[self databaseChanged: nil]; 
	}       
	[databases release];
	databases = dbs;
	[databases retain]; 
}    

- (void) setDatabasesResult: (QueryResult*) queryResult{    
	[databasesPopUp removeAllItems];	
	for(NSArray *row in [queryResult rows]){     
		NSString *title = [row objectAtIndex: 0];
		[databasesPopUp addItemWithTitle: title];
	} 
	[databasesPopUp selectItemWithTitle: [[self tdsConnection] currentDatabase]];
	[self databaseChanged: nil];	
}
 
#pragma mark ---- current database ---- 

- (void) displayDatabase{
	[databasesPopUp selectItemWithTitle: [queryController database]];  
	if (![databasesPopUp selectedItem]){ 
		[self setQueryDatabaseToDefault];
	}
}                                               

- (void) setQueryDatabaseToDefault{
		if ([self tdsConnection]){
			NSString *dbName = [[self tdsConnection] currentDatabase];
			if (dbName && [databasesPopUp itemWithTitle: dbName]){ 
				[queryController setDatabase: dbName];
			}
		}
}

- (void) databaseChanged:(id)sender{                              
	[queryController setDatabase: [sender titleOfSelectedItem]];	
}                                       

#pragma mark ---- database objects outline data source ---- 

-(NSArray*) dbObjectsForParent: (NSString*) parentId
{	
	if ([dbObjectsCache objectForKey:parentId] != nil){
		NSArray *item = [dbObjectsCache objectForKey:parentId]; 
		return item;
	}	
	NSMutableArray *selected = [NSMutableArray array];		
	for(int i=0; i<[dbObjectsResults count]; i++)
	{
		NSArray *row = [dbObjectsResults objectAtIndex:i];			
		if ([[row objectAtIndex:1] isEqualToString: parentId]){
			[selected addObject:row];
		}
	}		
	[dbObjectsCache setObject:selected forKey:parentId];	
	return selected;
}

-(NSArray*) dbObjectsForDatabase: (NSString*) database{	
	NSMutableArray *objects = [NSMutableArray array];
	[objects addObjectsFromArray: [self dbObjectsForParent: [NSString stringWithFormat: @"%@.%@", database, @"tables"]]];
	[objects addObjectsFromArray: [self dbObjectsForParent: [NSString stringWithFormat: @"%@.%@", database, @"views"]]];
	[objects addObjectsFromArray: [self dbObjectsForParent: [NSString stringWithFormat: @"%@.%@", database, @"procedures"]]];
	[objects addObjectsFromArray: [self dbObjectsForParent: [NSString stringWithFormat: @"%@.%@", database, @"functions"]]];   
	return objects;
}


- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {
	NSArray *selected = [self dbObjectsForParent: (item == nil ? @"" : [item objectAtIndex:0])];
	return [selected count];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {
	return [[item objectAtIndex:3 ] isEqualToString: @"NULL"];
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item {
	NSArray *selected = [self dbObjectsForParent: (item == nil ? @"" : [item objectAtIndex:0])];
	return [selected objectAtIndex:index];
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item {
	return [item objectAtIndex:2];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldEditTableColumn:(NSTableColumn *)tableColumn item:(id)item {
	return NO;
}

#pragma mark ---- database objects selected ----

- (NSArray*) selectedDbObject
{
	int row = [outlineView selectedRow];
	if( row >= 0 ){
		NSArray *item = [outlineView itemAtRow: row];
		if (![[item objectAtIndex:3 ] isEqualToString: @"NULL"]){
			return item;                                          
		}
	}

  return nil;
}     

- (NSArray*) selectedDbObjectName
{                                
	NSArray *selected = [self selectedDbObject];
	if (selected){
		return [selected objectAtIndex: 2];
	} 
	return nil;
}

- (void) databaseObjectSelected{
	//TODO ubaci ovo u text querija, na mjesto gdje je trenutni cursor
	NSLog(@"selected object name: %@", [self selectedDbObjectName]);
}                 

@end
