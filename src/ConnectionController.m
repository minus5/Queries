#import "ConnectionController.h"

@implementation ConnectionController

@synthesize outlineView;

#pragma mark ---- init ----

- (NSString*) windowNibName{
	return @"ConnectionView";
}

- (void) windowDidLoad{
	credentials = [[CredentialsController controller] retain];
	[queryTabBar setCanCloseOnlyTab: YES];         
	[self createNewTab];
	[self changeConnection: nil];                 	
	[self goToQueryText: nil];                                                    
	[outlineView setDoubleAction: @selector(databaseObjectSelected)];
}     

- (void) dealloc{
	NSLog(@"[%@ dealloc]", [self class]);
	[databases release];
	[dbObjectsResults release];	 
  [dbObjectsResultsAll release];
  [dbAllObjects release];
	[dbObjectsCache release];	  
	[connectionName release];
	[credentials release];
  [dbObjectsByDatabaseCache release];
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
	if (object == queryController){
		if ([keyPath isEqualToString: @"database"]){ 
			[self displayDatabase];		
		} 
		if ([keyPath isEqualToString: @"name"]){ 
			[[queryTabs selectedTabViewItem] setLabel: [queryController name]];
			[self displayDatabase];		
		}
		if ([keyPath isEqualToString: @"status"]){ 
			[self displayStatus];		
		}
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
	[self shouldCloseCurrentQuery];
	return [[queryTabs tabViewItems] count] > 0 ? NO : YES;	
}                                                                  

- (void) windowWillClose:(NSNotification *)notification
{                	
	[[NSApp delegate] performSelector:@selector(connectionWindowClosed:) withObject:self afterDelay:0.0];
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
	
	NSAlert *alert = [NSAlert alertWithMessageText: [NSString stringWithFormat: @"Do you want to save the changes you made in document?" ]
																	 defaultButton: @"Save"
																 alternateButton: @"Don't Save"
																		 otherButton: @"Cancel"
											 informativeTextWithFormat: @"Your changes will be lost if you don't save them."
										];

	[alert beginSheetModalForWindow: [self window]
										modalDelegate: self
									 didEndSelector: @selector(closeAlertEnded:code:context:)
											contextInfo: NULL 
	 ];
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
 
- (IBAction) closeWindow: (id) sender{
  int numberOfEditedQuries = [self numberOfEditedQueries];
	if (numberOfEditedQuries > 0){                         
		NSString *message = @"You have unsaved query. Close anyway?";
		if (numberOfEditedQuries > 1){                                                                                       
			message = [NSString stringWithFormat: @"You have %d unsaved queries. Close anyway?", numberOfEditedQuries];         
		}   										
		NSAlert *alert = [NSAlert alertWithMessageText: message
																		 defaultButton: @"Close"
																	 alternateButton: @"Don't Close"
																			 otherButton: nil								
												 informativeTextWithFormat: @"Your changes will be lost if you don't save them."];		
   
    [alert beginSheetModalForWindow: [self window]
										 modalDelegate :self
										 didEndSelector: @selector(closeWindowAlertEnded:code:context:)
												contextInfo: NULL ];                                                                                       
	}
}                                 

-(void) closeWindowAlertEnded:(NSAlert *) alert code:(int) choice context:(void *) v{   		
	if (choice == NSAlertDefaultReturn){   	     
    for(int i = [[queryTabs tabViewItems] count]; i>0; i--){
      [self closeCurentQuery];
    } 
  }
}

#pragma mark ---- connection ----

- (IBAction) changeConnection: (id) sender{ 
	[NSApp beginSheet: [credentials window]
		 modalForWindow: [self window]
			modalDelegate: self 
		 didEndSelector: @selector(didChangeConnection:returnCode:contextInfo:)
				contextInfo: nil];	
} 

//called by alert window after unsucessfull connecting
- (void) changeConnection:(NSAlert *) alert code:(int) choice context:(void *) v{
	[NSApp endSheet: [alert window]];
	[[alert window] orderOut: self];
	[self changeConnection: nil];
}

- (void) showConnectingSheet{
	NSString *connectionDescription = [NSString stringWithFormat: @"%@ as %@", [credentials server], [credentials user]];
	connectingController = [[ConnectingController alloc] initWithLabel: [NSString stringWithFormat: @"Connecting to %@ ...", connectionDescription]];
	[NSApp beginSheet: [connectingController window] 
		 modalForWindow: [self window] 
			modalDelegate: self 
		 didEndSelector: @selector(connectingSheetDidEnd:returnCode:contextInfo:)
				contextInfo: nil];
}                            

- (void) connectingSheetDidEnd:(NSWindow *)sheet 
										returnCode:(NSInteger)returnCode 
									 contextInfo:(void *)contextInfo{
	if (returnCode == NSRunAbortedResponse){
		[getConnectionThread cancel];		
		[self hideConnectingSheet];
		[self changeConnection: nil];
	}	
}

- (void) hideConnectingSheet{
	if (connectingController){
		[NSApp endSheet: [connectingController window]];
		[[connectingController window] orderOut: self];
		[connectingController release];
		connectingController = nil;
	}
}

- (void) didChangeConnection:(NSWindow *)sheet 
									returnCode:(NSInteger)returnCode 
								 contextInfo:(void *)contextInfo{
	if (returnCode != NSRunContinuesResponse)
		return;
	
	[self showConnectingSheet];
	
	NSDictionary* arguments = [NSDictionary dictionaryWithObjectsAndKeys: 
																						[credentials server]																				, @"server", 		
																					[credentials user]																					, @"user",
																					[credentials password]																			, @"password",
																					self																												, @"receiver",
																					NSStringFromSelector(@selector(didChangeConnection:))				, @"selector",
																					nil
														 ]; 


	[getConnectionThread release];
	getConnectionThread = [[NSThread alloc] 
												 initWithTarget: [ConnectionsManager sharedInstance]
															 selector: @selector(getConnection:) 
																 object: arguments];
	[getConnectionThread start];
}

- (void) didChangeConnection: (TdsConnection*) connection{
	[self hideConnectingSheet];
	
	if (!connection){
		NSString *connectionDescription = [NSString stringWithFormat: @"%@ as %@", [credentials server], [credentials user]];
		NSAlert *alert = [NSAlert alertWithMessageText: [NSString stringWithFormat: @"Unable to connect to %@ !", connectionDescription]
																		 defaultButton: nil
																	 alternateButton: nil
																			 otherButton: nil
												 informativeTextWithFormat: @""];
		
		[alert beginSheetModalForWindow: [self window]
											modalDelegate: self
										 didEndSelector: @selector(changeConnection:code:context:)
												contextInfo: NULL ];
		return;
	} 
		
	[credentials writeCredentials];			
	// [self setDefaultDatabase: [credentials currentDatabase]];
	
	[connectionName release];
	connectionName = [[connection connectionName] retain];
	[[self window] setTitle: [connection connectionName]];
	
	//[self databaseChanged: nil];	
	//[self databaseChangedTo: [credentials database]];

	[self dbObjectsFillSidebar];	
}              

- (TdsConnection*) tdsConnection{
	return [[ConnectionsManager sharedInstance] connectionWithName: connectionName];
}

-(IBAction) reloadDbObjects: (id) sender{
  [dbObjectsByDatabaseCache release];
  dbObjectsByDatabaseCache = nil;
	[self dbObjectsFillSidebar];
}                                        

#pragma mark ---- execute ----

-(IBAction) executeQuery: (id) sender{     
	if (!connectionName){                                                       			
		[self changeConnection: nil];
		return;		
	}    
  @try {
		[[self tdsConnection] executeInBackground: [queryController queryString] 
																 withDatabase: [queryController database]
															 returnToObject: queryController 
																 withSelector: @selector(setResult:)];		
	}
	@catch (NSException * e) {
		[self showException: e];		
	}		
}     

-(IBAction) executeQueryParagraph:(id)sender{     
	if (!connectionName){                                                       			
		[self changeConnection: nil];
		return;		
	}    
  @try {    
    //NSLog(@"query paragraph: %@", [queryController queryParagraphString]);
		[[self tdsConnection] executeInBackground: [queryController queryParagraphString]
																 withDatabase: [queryController database]
															 returnToObject: queryController 
																 withSelector: @selector(setResult:)];		
	}
	@catch (NSException * e) {
		[self showException: e];		
	}		
} 

- (void) showException: (NSException*) e {
	[queryController showErrorMessage: [NSString stringWithFormat:@"%@", e]];
}
                              
#pragma mark ---- explain ----

- (IBAction) explain: (id) sender{                                  
	@try{			
		NSArray *row = [self selectedDbObject];
		if (!row)
		  return;
					
		NSString *database = [row objectAtIndex: 4];
		NSString *collectionName = [row objectAtIndex: 5];
		NSString *type =  [[collectionName substringToIndex: [collectionName length] - 1] uppercaseString];
		NSString *nameWithSchema = [row objectAtIndex: 8];

		if ([collectionName isEqualToString: @"tables"]){
			CreateTableScript *scripter = [[[CreateTableScript alloc] 
																			 initWithConnection: [self tdsConnection]
																								 database: database 
																										table: nameWithSchema
																								 receiver: self
																								 selector: @selector(showExplainResult:)] 
																			autorelease];
			[scripter generate];
		}else{					
			CreateProcedureScript *scripter = [[[CreateProcedureScript alloc] 
																						initWithConnection: [self tdsConnection] 
																											database: database 
																												object: nameWithSchema
																													type: type
																											receiver: self
																											selector: @selector(showExplainResult:)] 
																					autorelease]; 
			[scripter generate];
		}	       
	}
	@catch(NSException *e){
		[self showException: e];				
		NSLog(@"explain exception %@", e);
	} 
}

- (void) showExplainResult: (NSArray*) data{
	[self createNewTab];              								                                                                           
	[queryController setString: [data objectAtIndex: 0]];    
	[queryController setName: [data objectAtIndex: 1]];
}

- (IBAction) openDocument:(id)sender{
	NSOpenPanel *panel = [NSOpenPanel openPanel];
	if ([panel runModal] == NSOKButton) { 
    [self openFile: [panel filename]];
	}
}

- (BOOL) openFile:(NSString*)filename{
  if ([queryController isEdited])
  	[self createNewTab];
  [queryController openFile: filename];
	return YES;
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
  NSEvent* e = [NSApp currentEvent];
  if([e type] == NSKeyDown){
		[self keyDown:e];
  } else {
		[super doCommandBySelector:aSelector];
  } 
}    


#pragma mark ---- database objects sidebar ----

-(void) dbObjectsFillSidebar{         
	[self readDatabases];			
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
		[databasesPopUp selectItemWithTitle: [credentials database]];
		// @try {  
    //   [[self tdsConnection] useDatabase: [self defaultDatabase]];    
    // }
    // @catch (NSException *e) {         
		// 	NSLog(@"exception %@", e);
		// }
		[self databaseChanged: nil]; 
	}       
	[databases release];
	databases = dbs;
	[databases retain];             
	[self readDatabaseObjects];
}

- (void) readDatabaseObjects{ 
  NSString *currentDatabase = [databasesPopUp titleOfSelectedItem];	
  if (dbObjectsResultsAll){
		NSArray *row = [dbObjectsResultsAll objectAtIndex: 0];
    NSString *dbInOutline = [row objectAtIndex:0];
    if ([dbInOutline isEqualToString: currentDatabase]){
      return;  
    }
  }


  if (dbObjectsByDatabaseCache != nil){
      if ([dbObjectsByDatabaseCache objectForKey:currentDatabase] != nil){
        //read database objects from cache
        [dbObjectsResultsAll release];
        dbObjectsResultsAll = [dbObjectsByDatabaseCache objectForKey:currentDatabase]; 
        [dbObjectsResultsAll retain];
        [self filterDatabaseObjects];
        return;
      }
	}	

  //read database objects from database
	@try{		
		[[self tdsConnection] executeInBackground: [self databaseObjectsQuery]
																 withDatabase: @"master" 
															 returnToObject: self
																 withSelector: @selector(setObjectsResult:)];		
	}
	@catch (NSException * e) {
		[self showException: e];		
	}			
}                                                                 
                                               
- (NSString*) databaseObjectsQuery{
	NSMutableString *query = [NSMutableString stringWithString:[ConnectionsManager sqlFileContent: @"objects_start"]];
	[query appendFormat: @"\n\n"];
	
	//dohvati objekte samo za trenutnu bazu
	NSString *currentDatabase = [databasesPopUp titleOfSelectedItem];	
	[query appendFormat: @"begin try\nuse %@\n\n", currentDatabase];
	[query appendFormat: @"%@\n", [ConnectionsManager sqlFileContent: @"objects_in_database2"]];
	[query appendFormat: @"\nend try\nbegin catch\nend catch\n", currentDatabase];
  
  
//	for(id db in databases){
//		[query appendFormat: @"begin try\nuse %@\n\n", db];
//		[query appendFormat: @"%@\n", [ConnectionsManager sqlFileContent: @"objects_in_database2"]];
//		[query appendFormat: @"\nend try\nbegin catch\nend catch\n", db];
//	}
 	
	[query appendFormat: @"%@\n", [ConnectionsManager sqlFileContent: @"objects_end"]];
	return query;
}

- (void) setObjectsResult: (QueryResult*) queryResult{ 
	[self clearObjectsCache];		
	[outlineView reloadData];
	
	[dbObjectsResultsAll release];
	dbObjectsResultsAll =  [queryResult rows];
	[dbObjectsResultsAll retain];
  
  //store objects in cache
  NSString *currentDatabase = [[dbObjectsResultsAll objectAtIndex:0] objectAtIndex:0];
  if (dbObjectsByDatabaseCache == nil){
    dbObjectsByDatabaseCache = [NSMutableDictionary dictionary];	
    [dbObjectsByDatabaseCache retain];
  }
  [dbObjectsByDatabaseCache setObject:dbObjectsResultsAll forKey:currentDatabase];	

	[self filterDatabaseObjects];
}
		    
- (void) filterDatabaseObjects{		
	
	NSString *filterString				= [searchField stringValue]; 	
	NSMutableSet *dbObjectsSet		= [NSMutableSet set];   
	BOOL useFilter								= filterString && [filterString length] > 0;
	NSString *currentDatabase			= [databasesPopUp titleOfSelectedItem];	
	NSString *regexFilterString		= [NSString stringWithFormat: @"(?im)%@", filterString];	
	NSMutableSet *dbAllObjectsSet = [NSMutableSet set]; 
  bool groupBySchema = [[[NSUserDefaults standardUserDefaults] objectForKey: QueriesGroupBySchema] boolValue];
		
	for(NSArray *row in dbObjectsResultsAll){
                    
		NSString *database   = [row objectAtIndex: 0];
		NSString *type       = [row objectAtIndex: 1];
		NSString *schema     = [row objectAtIndex: 2];
		NSString *name       = [row objectAtIndex: 3];                                       
		NSString *parentName = [row objectAtIndex: 4];
		
		NSString *id = [NSString stringWithFormat: @"%@.%@.%@.%@", database, schema, type, name];
		NSString *nameWithSchema = [NSString stringWithFormat: @"%@.%@", schema, name];
    NSString *displayName = groupBySchema ? name : nameWithSchema;
    if ([parentName length] > 0) {
      displayName = [NSString stringWithFormat: @"%@.%@", parentName , displayName];
    }
    [dbAllObjectsSet addObject: [NSArray arrayWithObjects: database, name, schema, nameWithSchema, nil]];
				
    if (!useFilter || ([database isEqualToString: currentDatabase] && [nameWithSchema isMatchedByRegex: regexFilterString])){			
			if (groupBySchema){
				NSString *level1 = [NSString stringWithFormat: @"%@.%@", database, schema]; 
		 	  NSString *level2 = [NSString stringWithFormat: @"%@.%@.%@", database, schema, type];
        [dbObjectsSet addObject: [NSArray arrayWithObjects: level1, @"", schema,   @"+", nil]];
				[dbObjectsSet addObject: [NSArray arrayWithObjects: level2, level1, type,     @"+", nil]];
				[dbObjectsSet addObject: [NSArray arrayWithObjects: id, 		level2, displayName,     @"",  database, type, schema, name, nameWithSchema, nil]];
						
			}else{							
				NSString *level1 = [NSString stringWithFormat: @"%@.%@", database, type];       
				[dbObjectsSet addObject: [NSArray arrayWithObjects: level1, @"", type,    				@"+", nil]];
				[dbObjectsSet addObject: [NSArray arrayWithObjects: id, 		level1, displayName, @"",  database, type, schema, name, nameWithSchema, nil]];
			}
		}
	}			
	[self clearObjectsCache];       
	dbObjectsResults = [[dbObjectsSet allObjects] retain]; 
  dbAllObjects = [[dbAllObjectsSet allObjects] retain]; 
	
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
	[databasesPopUp selectItemWithTitle: [credentials database]];   
	[self databaseChanged: nil];	
}             

- (IBAction) searchDatabaseObjects: (id) sender{
	[self filterDatabaseObjects];	
}

- (IBAction) selectFilter: (id) sender{
	[[self window] makeFirstResponder: searchField]; 
}
 
#pragma mark ---- current database ---- 

//when db in query controllers changes, when current tab changes, or query execution changes database (use)
- (void) displayDatabase{
	NSString *database = [queryController database];
	NSLog(@"displayDatabase: %@", database);	
	[databasesPopUp selectItemWithTitle: database];  
	[credentials setCurrentDatabase: database]; 
	if (![databasesPopUp selectedItem]){ 
		[self setQueryDatabaseToDefault];
	}
	[self readDatabaseObjects];
}                                               

- (void) setQueryDatabaseToDefault{
	@try{
		NSString *dbName = [[self tdsConnection] currentDatabase];
		if (dbName && [databasesPopUp itemWithTitle: dbName]){ 
			[queryController setDatabase: dbName];
		}
	}		
	@catch (NSException * e) {
		NSLog(@"setQueryDatabaseToDefault exception %@", e);	
	}		
}

//called when UI combo value changes
- (void) databaseChanged:(id)sender{    
	[self databaseChangedTo: [databasesPopUp titleOfSelectedItem]];
} 

- (void) databaseChangedTo:(NSString*) database{
	NSLog(@"databaseChangedTo: %@", database);
  [queryController setDatabase: database]; 
	[credentials setCurrentDatabase: database]; 
	if ([[searchField stringValue] length] > 0){                  
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
		for (NSArray *row in dbAllObjects){
			//if ([row count] == 9){
			if ([[row objectAtIndex:0] isEqualToString: database]){									
			
				NSString *name = [row objectAtIndex: 1];
				NSString *nameWithSchema = [row objectAtIndex: 3];
				
				if (NSOrderedSame == [name compare:searchString options:NSCaseInsensitiveSearch range: r] ||
						NSOrderedSame == [nameWithSchema compare:searchString options:NSCaseInsensitiveSearch range: r]){
					[objectNames addObject: nameWithSchema];
				}				
			}    								
			//}	
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
  [self explain: nil];
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
