#import "CocoaQueryAnalyzerAppDelegate.h"

@implementation CocoaQueryAnalyzerAppDelegate

@synthesize window;

- (void)awakeFromNib{
	[queryText setFont: [NSFont fontWithName: @"Monaco" size: 13.0]];
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


@end
