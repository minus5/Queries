#import "ConnectionController.h"

@implementation ConnectionController

@synthesize outlineView, defaultDatabase;;

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
	[controller removeObserver: self forKeyPath: @"status"];
	[tabViewItem release];
	[controller release];                                                                                 
		
	if ([[queryTabs tabViewItems] count] == 0)
		[[self window] close];
	else{
		if (previousSelectedTabViewItem != NULL)
			[queryTabs selectTabViewItem: previousSelectedTabViewItem];		
	}
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
	previousSelectedTabViewItem = [queryTabs selectedTabViewItem];                                          
	if (previousSelectedTabViewItem != tabViewItem){
		[queryTabs selectTabViewItem: tabViewItem];
	}else{
		previousSelectedTabViewItem = NULL; 
	}	
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
		TdsConnection *newConnection = [[ConnectionsManager sharedInstance] connectionToServer: [credentials server] 
		  withUser: [credentials user] 
		  andPassword:[credentials password]];		
		[credentials writeCredentials];		
    [self setDefaultDatabase: [credentials currentDatabase]];
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
		
  [[self tdsConnection] updateCredentials];
}                                 
                              
#pragma mark ---- explain ----

-(IBAction) explain: (id) sender{                                  
	@try{			
		NSArray *row = [self selectedDbObject];
		if (!row)
		  return;
					
		NSString *database = [row objectAtIndex: 4];
		NSString *type = [row objectAtIndex: 5];
		NSString *nameWithSchema = [row objectAtIndex: 8];

		if ([type isEqualToString: @"tables"]){
		  [self createNewTab];  		                                           
			[queryController setString: [CreateTableScript scriptWithConnection: [self tdsConnection] database: database table: nameWithSchema]];
			[queryController setName: nameWithSchema];
			return;
		}					
		if ([type isEqualToString: @"procedures"] || [type isEqualToString: @"functions"] || [type isEqualToString: @"views"]){	
			//QueryResult *queryResult = [[self tdsConnection] execute: [NSString stringWithFormat: @"use %@\nexec sp_helptext '%@'", database, nameWithSchema]];
			QueryResult *queryResult = [[self tdsConnection] execute: [NSString stringWithFormat: @"use %@\nselect text from syscomments where id = object_id('%@')", database, nameWithSchema]];
			
			if (queryResult){
				//create to alter
				NSString *typeName =  [[type substringToIndex: [type length] - 1] uppercaseString];
				NSString *script = [queryResult resultAsString];                                                                             				
				NSString *createRegexString = [NSString stringWithFormat: @"(?im)(^\\s*CREATE\\s+%@\\s+)", typeName]; 
				NSString *alterRegexString = [NSString stringWithFormat: @"ALTER %@ ", typeName]; 
				script = [script stringByReplacingOccurrencesOfRegex:createRegexString withString:alterRegexString];                                        
				
				[self createNewTab];              								                                                                           
				[queryController setString: script];    
				[queryController setName: nameWithSchema];
			}
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
    [self openFile: [panel filename]];
	}
}

- (void) openFile:(NSString*)filename{
  if ([queryController isEdited])
  	[self createNewTab];
  [queryController openFile: filename];
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
	if ( ( [theEvent modifierFlags] & NSCommandKeyMask ) && ( [theEvent modifierFlags] & NSShiftKeyMask ) ){
		if ([theEvent keyCode] == 30)
			[self nextTab: nil];                                               
		if ([theEvent keyCode] == 33)
			[self previousTab: nil];		                                       
		return;
	}
	//command-1 command-0 odabire odredjni tab
	if ( [theEvent modifierFlags] & NSCommandKeyMask && [theEvent keyCode] > 17 && [theEvent keyCode] < 30)
	{     
		int tabIndex = [theEvent keyCode] - 18;
		switch ([theEvent keyCode]) {
			case 23:
				tabIndex = 4;
				break;					
			case 22:
				tabIndex = 5;
				break;
			case 26:
				tabIndex = 6;
				break;		
			case 28:
				tabIndex = 7;
				break;		
			case 25:
				tabIndex = 8;
				break;
			case 29:
				tabIndex = 9;
				break;						
			default:
				break;
		}		
		if ([[queryTabs tabViewItems] count] > tabIndex)
			[queryTabs selectTabViewItemAtIndex:tabIndex];
	}
			
	NSLog(@"keyDown event keyCode %d modifierFlags: %d window %@", [theEvent keyCode], [theEvent modifierFlags], [theEvent window]);	
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
		[databasesPopUp removeAllItems];      
						 		
		[self clearObjectsCache];		
		[outlineView reloadData];
		
		[self readDatabases];		
	}@catch(NSException *exception){    
		NSLog(@"error in dbObjectsFillSidebar: %@", exception);
	}
}                         

- (void) readDatabases{
	[[self tdsConnection] executeInBackground: @"select name from master.sys.databases where state_desc = 'ONLINE' and (owner_sid != 01 or name = 'master') and isnull(has_dbaccess([Name]), 0) = 1 order by name"
		withDatabase: @"master" 
		returnToObject: self
		withSelector: @selector(setDatabasesQueryResult:)];
}  

- (void) setDatabasesQueryResult: (QueryResult*) queryResult{	  
	NSMutableArray *dbs = [NSMutableArray array];    
	if (queryResult){         
		[databasesPopUp removeAllItems];
		for(NSArray *row in [queryResult rows]){     
			NSString *title = [row objectAtIndex: 0];
			[dbs addObject: title];
			[databasesPopUp addItemWithTitle: title];
		} 
		@try {  
      [[self tdsConnection] useDatabase: [self defaultDatabase]];    
    }
    @catch (NSException *e) {         
  		 NSLog(@"exception %@", e);
		}
		[self databaseChanged: nil]; 
	}       
	[databases release];
	databases = dbs;
	[databases retain];             
	[self readDatabaseObjects];
}

- (void) readDatabaseObjects{        
	[outlineView setDoubleAction: @selector(databaseObjectSelected)];
	[[self tdsConnection] executeInBackground: [self databaseObjectsQuery]
		withDatabase: @"master" 
		returnToObject: self
		withSelector: @selector(setObjectsResult:)];		
}                                                                 
                                               
- (NSString*) databaseObjectsQuery{
	NSMutableString *query = [NSMutableString stringWithString:[ConnectionsManager sqlFileContent: @"objects_start"]];
	[query appendFormat: @"\n\n"];
	for(id db in databases){
		[query appendFormat: @"begin try\nuse %@\n\n", db];
		[query appendFormat: @"%@\n", [ConnectionsManager sqlFileContent: @"objects_in_database2"]];
		[query appendFormat: @"\nend try\nbegin catch\nend catch\n", db];
	} 	
	[query appendFormat: @"%@\n", [ConnectionsManager sqlFileContent: @"objects_end"]];
	return query;
}

- (void) setObjectsResult: (QueryResult*) queryResult{ 
	[dbObjectsResultsAll release];
	dbObjectsResultsAll =  [queryResult rows];
	[dbObjectsResultsAll retain];
	[self filterDatabaseObjects];
}
		    
- (void) filterDatabaseObjects{		
	
	NSString *filterString = [searchField stringValue]; 	
	NSMutableSet *dbObjectsSet = [NSMutableSet set];   
	BOOL useFilter = filterString && [filterString length] > 0;
	NSString *currentDatabase = [databasesPopUp titleOfSelectedItem];	
	NSString *regexFilterString = [NSString stringWithFormat: @"(?im)%@", filterString];
		
	for(NSArray *row in dbObjectsResultsAll){
                    
		
		NSString *database = [row objectAtIndex: 0];
		NSString *type = [row objectAtIndex: 1];
		NSString *schema = [row objectAtIndex: 2];
		NSString *name = [row objectAtIndex: 3];                                       
		
		NSString *id = [NSString stringWithFormat: @"%@.%@.%@.%@", database, schema, type, name];
		NSString *nameWithSchema = [NSString stringWithFormat: @"%@.%@", schema, name];
		NSString *level1 = database;
				
		//if (!useFilter || ([database isEqualToString: currentDatabase] && ([name hasPrefix: filterString] || [schema hasPrefix: filterString])) ){
    if (!useFilter || ([database isEqualToString: currentDatabase] && [nameWithSchema isMatchedByRegex: regexFilterString])){			
			if ([[[NSUserDefaults standardUserDefaults] objectForKey: QueriesGroupBySchema] boolValue]){
				NSString *level2 = [NSString stringWithFormat: @"%@.%@", database, schema]; 
		 	  NSString *level3 = [NSString stringWithFormat: @"%@.%@.%@", database, schema, type];
					
				[dbObjectsSet addObject: [NSArray arrayWithObjects: level1, @"",    database, @"+", nil]];
				[dbObjectsSet addObject: [NSArray arrayWithObjects: level2, level1, schema,   @"+", nil]];
				[dbObjectsSet addObject: [NSArray arrayWithObjects: level3, level2, type,     @"+", nil]];
				[dbObjectsSet addObject: [NSArray arrayWithObjects: id, 		level3, name,     @"",  database, type, schema, name, nameWithSchema, nil]];
						
			}else{							
				NSString *level2 = [NSString stringWithFormat: @"%@.%@", database, type];
			 								
				[dbObjectsSet addObject: [NSArray arrayWithObjects: level1, @"",    database,       @"+", nil]];
				[dbObjectsSet addObject: [NSArray arrayWithObjects: level2, level1, type,    				@"+", nil]];
				[dbObjectsSet addObject: [NSArray arrayWithObjects: id, 		level2, nameWithSchema, @"",  database, type, schema, name, nameWithSchema, nil]];
			}
		}
	}			
	[self clearObjectsCache];       
	dbObjectsResults = [[dbObjectsSet allObjects] retain];  
	
	[outlineView reloadData];
	[outlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO]; 
	if (useFilter){
		[outlineView expandItem:nil expandChildren:YES]; 
	}
}   

- (void) clearObjectsCache{      
	[dbObjectsResults release];	
	dbObjectsResults = nil;
	[dbObjectsCache release];		
	dbObjectsCache = [NSMutableDictionary dictionary];		
	[dbObjectsCache retain];
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

- (IBAction) searchDatabaseObjects: (id) sender{
	[self filterDatabaseObjects];	
}

- (IBAction) selectFilter: (id) sender{
	[[self window] makeFirstResponder: searchField]; 
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
  NSString* database = [sender titleOfSelectedItem];                          
  [queryController setDatabase: database];  
	if ([[searchField stringValue] length] > 0){                  
    [self setDefaultDatabase: database]; 
		[self filterDatabaseObjects];
	}
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

-(NSArray*) objectNamesForAutocompletionInDatabase: (NSString*)database withSearchString: (NSString*)searchString{	
	NSMutableArray *objectNames = [NSMutableArray array]; 
	if ([searchString length] > 0){
		NSRange r = {0, [searchString length]};
		for (NSArray *row in dbObjectsResults){
			if ([row count] == 9){
				if ([[row objectAtIndex:4] isEqualToString: database]){									
			
					NSString *name = [row objectAtIndex: 7];
					NSString *nameWithSchema = [row objectAtIndex: 8];
				
					if (NSOrderedSame == [name compare:searchString options:NSCaseInsensitiveSearch range: r] ||
							NSOrderedSame == [nameWithSchema compare:searchString options:NSCaseInsensitiveSearch range: r]){
						[objectNames addObject: nameWithSchema];
					}				
				}    								
			}	
		}
	}	
	return objectNames;
}

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {
	NSArray *selected = [self dbObjectsForParent: (item == nil ? @"" : [item objectAtIndex:0])];
	return [selected count];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {
	return [[item objectAtIndex:3 ] isEqualToString: @"+"];
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
	int rowIndex = [outlineView selectedRow];
	if( rowIndex >= 0 ){
		NSArray *row = [outlineView itemAtRow: rowIndex];
		if ([row count] == 9)
			return row;
	}
  return nil;
}     

- (NSArray*) selectedDbObjectName
{                                
	NSArray *row = [self selectedDbObject];
	if (row){ 				
		return [row objectAtIndex: 8];
	} 
	return nil;
}

- (void) databaseObjectSelected{
	//TODO ubaci ovo u text querija, na mjesto gdje je trenutni cursor
	NSLog(@"selected object name: %@", [self selectedDbObjectName]);
} 

#pragma mark ---- drag and drop ----

- (NSArray *)allowedDraggedTypesForTabView:(NSTabView *)aTabView
{
	return [NSArray arrayWithObjects:NSFilenamesPboardType, NSStringPboardType, nil];
}

- (BOOL)tabView:(NSTabView*)aTabView shouldDragTabViewItem:(NSTabViewItem *)tabViewItem fromTabBar:(PSMTabBarControl *)tabBarControl
{
	return YES;
}

- (BOOL)tabView:(NSTabView*)aTabView shouldDropTabViewItem:(NSTabViewItem *)tabViewItem inTabBar:(PSMTabBarControl *)tabBarControl
{                               
	return queryTabs == aTabView;
}
                
@end
