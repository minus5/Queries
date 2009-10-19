#import "CocoaQueryAnalyzerAppDelegate.h"

#import "NoodleLineNumberView.h"
#import "NoodleLineNumberMarker.h"
#import "MarkerLineNumberView.h"


@implementation CocoaQueryAnalyzerAppDelegate

@synthesize window;

- (void)awakeFromNib{
	//[queryText setFont: [NSFont fontWithName: @"Monaco" size: 12.0]];  		
	[tabBarResults setDisableTabClose: 1];
		
	queryTextLineNumberView = [[MarkerLineNumberView alloc] initWithScrollView:queryTextScrollView];
  [queryTextScrollView setVerticalRulerView:queryTextLineNumberView];
  [queryTextScrollView setHasHorizontalRuler:NO];
  [queryTextScrollView setHasVerticalRuler:YES];
  [queryTextScrollView setRulersVisible:YES];  
  [queryText setFont:[NSFont userFixedPitchFontOfSize:[NSFont smallSystemFontSize]]];      

	[logTextView setFont:[NSFont userFixedPitchFontOfSize:[NSFont smallSystemFontSize]]];      	 
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	[self connectionSettings: nil];       
}      
             
-(void) applicationShouldTerminateAlertEnded:(NSAlert *) alert code:(int) choice context:(void *) v{
	if (choice == NSAlertAlternateReturn){   
		[NSApp replyToApplicationShouldTerminate: NSTerminateCancel];
	}else{
		[NSApp replyToApplicationShouldTerminate: NSTerminateNow];
	}			
}                         

-(BOOL) hasEditedQueries{
	for(id item in [tabView tabViewItems]){
		if ([[item identifier] isEdited])
			return TRUE;
	}
	return FALSE;
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender{  	
	if ([self hasEditedQueries]){
		NSAlert *alert = [NSAlert alertWithMessageText: @"You have unsaved queries. Quit anyway?"
			defaultButton: @"Quit"
			alternateButton: @"Don't Quit"
      otherButton: nil								
      informativeTextWithFormat: @"Your changes will be lost if you don't save them."];
			
		[alert beginSheetModalForWindow: window
			modalDelegate :self
			didEndSelector: @selector(applicationShouldTerminateAlertEnded:code:context:)
			contextInfo: NULL ];
			
		return NSTerminateLater;				  
	}	
	return NSTerminateNow;
}

-(IBAction) connectionSettings: (id) sender{
	[NSApp beginSheet:connectionSettingsWindow modalForWindow:window
			modalDelegate:nil didEndSelector:nil contextInfo:nil];
}        

- (void)textDidChange:(NSNotification *)aNotification{
	[self saveCurrentQueryTextAndSelection];            
	[queryExec setIsEdited: TRUE];
}

- (void)tabView:(NSTabView *)aTabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem
{ 
	[self changeQuery: [tabViewItem identifier]];	
}     

- (void)tabView:(NSTabView *)aTabView didCloseTabViewItem:(NSTabViewItem *)tabViewItem
{       
	[[tabViewItem identifier] release];
	NSLog(@"didCloseTabViewItem: %@", [tabViewItem label]);
} 

- (NSString *)tabView:(NSTabView *)aTabView toolTipForTabViewItem:(NSTabViewItem *)tabViewItem{
	if (aTabView == tabView){
		return [[tabViewItem identifier] connectionName];
	}else{
		return nil;
	}
}

-(void) addNewQueryTab: (QueryExec*) newQuery{
	NSString *label = [NSString stringWithFormat: @"Query %d", ++queryCounter];			
	NSTabViewItem *newItem = [[[NSTabViewItem alloc] initWithIdentifier:newQuery] autorelease];
	[newItem setLabel: label];
	[tabView addTabViewItem:newItem];
	[tabView selectTabViewItem:newItem]; 
}                                     

-(IBAction) newQuery: (id) sender{        
		QueryExec *newQuery = [self createQuery];
		if (newQuery != nil){
			[self addNewQueryTab: newQuery];										      
		}
}   

-(QueryExec*) createQuery{	
	@try{
		QueryExec *newQuery = [self createQueryExec];
		[self logMessage: [NSString stringWithFormat: @"Connected to: %@\n", [newQuery connectionName]]]; 
		return newQuery;
	}@catch(NSException *exception){
		[self logMessage: [NSString stringWithFormat: @"Failed connecting to: %@\n", [queryExec connectionName]]];
		[self logMessage: [NSString stringWithFormat:@"%@", [exception reason]]];
		return nil;
	}	
}

-(QueryExec*) createQueryExec{
	QueryExec *newQuery = [QueryExec alloc];
	[newQuery initWithCredentials: [serverNameTextField stringValue] 
										databaseName: [databaseNameTextField stringValue] 
												userName: [userNameTextField stringValue] 
												password: [passwordTextField stringValue] ];	
	[newQuery login];
	return newQuery;
}                 
      
-(void) changeQuery: (QueryExec*) new{
	[self saveCurrentQueryTextAndSelection];
	queryExec = new;
	[queryText setString: [queryExec queryText]];
	[self bindResult];	
}

-(IBAction) previousQuery: (id) sender{ 
	[tabView selectPreviousTabViewItem: nil];
}                    

-(IBAction) nextQuery: (id) sender{     
	[tabView selectNextTabViewItem: nil];
}  

-(void) saveCurrentQueryTextAndSelection{
	[queryExec setQueryText: [queryText string]];
	[queryExec setSelection: [queryText selectedRange]];	
}                          

-(void) closeAlertEnded:(NSAlert *) alert code:(int) choice context:(void *) v{
	if (choice == NSAlertOtherReturn){
		return;
	}	
	if (choice == NSAlertDefaultReturn){
		if (![self saveQuery]){ 
			return; 
		}
	}
	[tabView removeTabViewItem:[tabView selectedTabViewItem]];
}

-(IBAction) closeQuery: (id) sender{     
	if ([[tabView tabViewItems] count] == 1){
		return;
	}
	if ([queryExec isEdited]){          
		NSString *message = [NSString stringWithFormat: @"Do you want to save the changes you made in document '%@'?", [queryExec connectionName] ];
		NSAlert *alert = [NSAlert alertWithMessageText: message
			defaultButton: @"Save"
			alternateButton: @"Don't Save"
			otherButton: @"Cancel"
      informativeTextWithFormat: @"Your changes will be lost if you don't save them."];
			
		[alert beginSheetModalForWindow: window
			modalDelegate :self
			didEndSelector: @selector(closeAlertEnded:code:context:)
			contextInfo: NULL ];
			
	  return;
	}        		
	[tabView removeTabViewItem:[tabView selectedTabViewItem]];	
}

-(IBAction) connect: (id) sender{
		QueryExec *newQuery = [self createQuery];
		if (newQuery != nil){                   
			if (queryExec != nil){
				[[tabView selectedTabViewItem] setIdentifier: newQuery];
				[queryExec release];
				queryExec = newQuery;
				[self saveCurrentQueryTextAndSelection];				
			}else{										
				[self addNewQueryTab: newQuery];
				[self fillSidebar];
			}
			[self changeQuery: newQuery];		       			
			
			[NSApp endSheet:connectionSettingsWindow];
			[connectionSettingsWindow orderOut:sender];						    			
		}
}

-(void) fillSidebar{         
	@try{
		[sidebarQueryExec release];
	  sidebarQueryExec = [self createQueryExec];
		[sidebarQueryExec retain];
		[sidebarQueryExec execute: @"exec sp_cqa_database_objects"];
		[dbObjectsResults release];
		dbObjectsResults = [sidebarQueryExec rows];
		[dbObjectsResults retain];
		[cache release];		
		cache = [NSMutableDictionary dictionary];		
		[cache retain];
		[outlineView reloadData];
	}@catch(NSException *exception){    
		NSLog(@"error in fillSidebar: %@", exception);
	}
}

- (void) logMessage: (NSString*) message{
	[logTextView insertText: message];	
}

- (IBAction) nextResult: (id) sender {
	[queryExec nextResult];
	[self bindResult];
}

- (IBAction) previousResult: (id) sender {
	[queryExec previousResult];
	[self bindResult];
}

-(void) enableButtons{
	[previousResultMenu setEnabled: [queryExec hasPreviosResults]];
	[nextResultMenu setEnabled: [queryExec hasNextResults]];   
	//TODO dodaj i previous/next query buttons
}
   
- (IBAction) executeQuery: (id) sender {	
	 
	[self saveCurrentQueryTextAndSelection];
	[queryExec execute];						
	[self bindResult];
	
}                                               

-(void) showMessages{
	[logTextView setString:@""];
	for(id message in [queryExec messages]){			
		[logTextView insertText: message];	
	}   
	[logTextView insertText: @"\n"];		
} 

-(IBAction) showResults: (id) sender{
	[tabViewResults selectTabViewItemAtIndex: 0];	
}
-(IBAction) showMessages: (id) sender{
	[tabViewResults selectTabViewItemAtIndex: 1];
}


-(void) setResultsTabLabel{
	NSString *resultsTabLabel = @"Results";
	if ([queryExec resultsCount] > 1){
		resultsTabLabel = [NSString stringWithFormat:@"Results %d of %d", [queryExec currentResultIndex] + 1, [queryExec resultsCount]];
	}
	[[tabViewResults tabViewItemAtIndex: 0] setLabel: resultsTabLabel];
		
	[queryExec hasResults] ? [self showResults: nil] : [self showMessages:nil];
}

-(void) bindResult{		
	[self setResultsTabLabel];
	[self enableButtons];         
	[self showMessages];
	[self removeAllColumns];							
	[self addColumns];							
	[tableView reloadData];	      			       
	[[tabView selectedTabViewItem] setLabel:[queryExec connectionName]];
}

-(void) addColumns{
	NSArray *columns = [queryExec columns];
	for(int i=0; i<[columns count]; i++){
		[self addColumn: [columns objectAtIndex: i]];		
	}
}

-(void) addColumn:(ColumnMetadata*) meta{
	NSTableColumn *column;
	column = [[NSTableColumn alloc] initWithIdentifier: meta.name];
	[tableView addTableColumn: column];	
	
	[[column headerCell] setStringValue:meta.name];
	[column setIdentifier: [NSNumber numberWithInt: meta.index]];	
	[column setWidth: 80];
	[[column dataCell] setFont: [NSFont fontWithName: @"Lucida Grande" size: 11.0]];
	
	switch (meta.type) {
		case SYBINTN:
		case SYBINT2:
		case SYBINT4:
			[[column dataCell] setAlignment: NSRightTextAlignment];
			[column setWidth: 80];
			break;			
		case SYBMONEY:
		case SYBMONEY4:			
		case SYBREAL:
		case SYBNUMERIC:		
			[[column dataCell] setAlignment: NSRightTextAlignment];
			[column setWidth: 100];
			break;
		case SYBBIT:
			[[column dataCell] setAlignment: NSCenterTextAlignment];
			[column setWidth: 50];
			break;
		case SYBCHAR:
		case SYBVARCHAR:
		case SYBDATETIME:
		case SYBDATETIME4:
		case SYBDATETIMN:			
			[column setWidth: 150];
		default:
			break;
	}		
	//NSLog(@"column: %@ %d %d", meta.name, meta.type, meta.size); 	
	[column retain];
}

-(void)removeAllColumns{
	int count = [[tableView tableColumns] count];
	for(int i = count - 1; i >= 0; i--){
		NSTableColumn *col = [[tableView tableColumns] objectAtIndex: i];
		[tableView removeTableColumn: col];
	}
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView{	
	return [queryExec rowsCount];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {		
	return [queryExec rowValue: rowIndex: [[aTableColumn identifier] integerValue]];
}

#pragma mark Sidebar data source methods

-(NSArray*) objectsForParent: (NSString*) parentId
{
	
	if ([cache objectForKey:parentId] != nil){
		NSArray *item = [cache objectForKey:parentId]; 
		return item;
	}
	
	NSMutableArray *selected = [NSMutableArray array];		
	NSLog(@"searching for childs of: %@", parentId);
	
	for(int i=0; i<[dbObjectsResults count]; i++)
	{
		NSArray *row = [dbObjectsResults objectAtIndex:i];			
		if ([[row objectAtIndex:1] isEqualToString: parentId]){
			[selected addObject:row];
		}
	}		
	[cache setObject:selected forKey:parentId];	
	return selected;
}

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {
	NSArray *selected = [self objectsForParent: (item == nil ? @"" : [item objectAtIndex:0])];
	return [selected count];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {
	return [[item objectAtIndex:3 ] isEqualToString: @"NULL"];
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item {
	NSArray *selected = [self objectsForParent: (item == nil ? @"" : [item objectAtIndex:0])];
	return [selected objectAtIndex:index];
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item {
	return [item objectAtIndex:2];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldEditTableColumn:(NSTableColumn *)tableColumn item:(id)item {
	return NO;
}

#pragma mark show selected database object            

- (NSArray*) selectedSidebarItem
{
    int row = [outlineView selectedRow];
    if( row >= 0 )
        return [outlineView itemAtRow: row];
    else
        return nil;
}                               
 
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
			if ([sidebarQueryExec execute: [NSString stringWithFormat: @"use %@\nexec sp_helpText '%@'", databaseName, fullName]]){
				[self newQuery: nil]; 
				[queryText setString: [sidebarQueryExec resultAsString]];
			}
		}	
	}
}                                         

#pragma mark open save documnet

- (IBAction)openDocument:(id)sender {
	NSOpenPanel *panel = [NSOpenPanel openPanel];
	if ([panel runModal] == NSOKButton) {
		NSString *fileName = [panel filename];
		NSString *fileContents = [NSString stringWithContentsOfFile:fileName encoding:NSUTF8StringEncoding error:NULL];
		[queryText setString:fileContents];
	}
}

- (IBAction)saveDocument:(id)sender {
	[self saveQuery];
}     

- (BOOL) saveQuery{
	
	NSString *fileName = [queryExec fileName];

	if (fileName == nil){
		NSSavePanel *panel = [NSSavePanel savePanel];
		[panel setRequiredFileType:@""];
		if ([panel runModal] == NSOKButton) {
			fileName = [panel filename];
			[queryExec setFileName: fileName];
		}else{
			return NO;
		}			
	}
	
	[[queryText string] writeToFile: fileName 
		atomically:YES 
		encoding:NSUTF8StringEncoding error:NULL];
		
	[self saveCurrentQueryTextAndSelection];
	[queryExec setIsEdited: NO];            
	
	return YES;
}

- (IBAction)newDocument:(id)sender{
	[self newQuery:sender];
}
- (IBAction)performClose:(id)sender{
	[self closeQuery:sender];
}

@end
