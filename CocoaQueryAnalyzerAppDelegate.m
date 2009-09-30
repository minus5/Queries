#import "CocoaQueryAnalyzerAppDelegate.h"

@implementation CocoaQueryAnalyzerAppDelegate

@synthesize window;

- (void)awakeFromNib{
	[queryText setFont: [NSFont fontWithName: @"Monaco" size: 12.0]];
	cache = [NSMutableDictionary dictionary];
	[cache retain];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	[self connectionSettings: nil];
}

-(IBAction) connectionSettings: (id) sender{
	[NSApp beginSheet:connectionSettingsWindow modalForWindow:window
			modalDelegate:nil didEndSelector:nil contextInfo:nil];
}

-(IBAction) connect: (id) sender{
	@try{			
		[queryExec dealloc];
		queryExec = [QueryExec alloc];
		[queryExec initWithCredentials: [serverNameTextField stringValue] 
											databaseName: [databaseNameTextField stringValue] 
													userName: [userNameTextField stringValue] 
													password: [passwordTextField stringValue] ];
		
		[queryExec login];
		
		[queryExec execute: @"exec cocoa_query_analyzer.database_objects"];
		cache = [NSMutableDictionary dictionary];
		[cache retain];
		[self bindResult];
						
		[NSApp endSheet:connectionSettingsWindow];
		[connectionSettingsWindow orderOut:sender];				
		[window setTitle: [queryExec connectionName]];
    
		[self logMessage: [NSString stringWithFormat: @"Connected to: %@\n", [queryExec connectionName]]]; 
	}@catch(NSException *exception){
		[self logMessage: [NSString stringWithFormat: @"Failed connecting to: %@\n", [queryExec connectionName]]];
		[self logMessage: [NSString stringWithFormat:@"%@", [exception reason]]];
		
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
}

-(NSString*) query{
	NSString *q = [queryText string];		
	NSRange selection = [queryText selectedRange];
	if(selection.length > 0){
		q = [q substringWithRange: selection];
	}		
	return q;
}

- (IBAction) executeQuery: (id) sender {	
	
	[queryExec execute: [self query]];				
	
	if ([queryExec hasResults]) {
		[self bindResult];
	}			
			
  if([queryExec hasMessages]){
		NSArray *messages = [queryExec getMessages];
		for(int i=0; i<[messages count]; i++){
		  [logTextView insertText: [messages objectAtIndex: i]];	
		}
		[logTextView insertText: @"\n"];
	}
}

-(void) bindResult{
	[self enableButtons];
	[self removeAllColumns];							
	[self addColumns];						
	[tableView reloadData];	
	[outlineView reloadData];
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


// Data Source methods

-(NSArray*) objectsForParent: (NSString*) parentId
{
	
	if ([cache objectForKey:parentId] != nil){
		NSLog(@"found in cache");
		return [cache objectForKey:parentId];
	}
	
	NSMutableArray *selected = [NSMutableArray array];		
	NSLog(@"searching for childs of: %@", parentId);
	
	for(int i=0; i<[queryExec rowsCount]; i++)
	{
		NSArray *row = [[queryExec rows] objectAtIndex:i];			
		if ([[row objectAtIndex:1] isEqualToString: parentId]){
			[selected addObject:row];
		}
	}	
	
	[selected	retain];
	[cache setObject:selected forKey:parentId];
	
	return selected;
}


- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {
	NSArray *selected = [self objectsForParent: (item == nil ? @"" : [item objectAtIndex:0])];
	return [selected count];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {
	return ![[item objectAtIndex:3 ] isEqualToString: @"0"];
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item {
	NSArray *selected = [self objectsForParent: (item == nil ? @"" : [item objectAtIndex:0])];
	return [selected objectAtIndex:index];
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item {
//	if ([[tableColumn identifier] isEqualToString: @"objectsCount"])
//	{
//		NSString *objectsCount = [item objectAtIndex:3];
//		if (![objectsCount isEqualToString:	@"0"]){			
//			return [item objectAtIndex:3];
//		}else
//		{
//			return nil;
//		}
//	}
//	else {
		return [item objectAtIndex:2];
//	}	
}

// Delegate methods
- (BOOL)outlineView:(NSOutlineView *)outlineView shouldEditTableColumn:(NSTableColumn *)tableColumn item:(id)item {
	return NO;
}




@end
