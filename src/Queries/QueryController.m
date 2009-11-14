#import "QueryController.h"

@implementation QueryController

@synthesize isEdited, isProcessing, fileName, database, name;
                           
#pragma mark ---- properties ----

- (void) processingStarted{
	[self setIsProcessing: YES];
	[messagesTextView insertText: @"\nExecuting query...\n"];
}

- (void) setIsEdited: (BOOL) value{
	if (value != isEdited){
		isEdited = value;
		[connection isEditedChanged: self];
	}
}

- (NSString*) queryString{          
	NSRange selection = [queryText selectedRange]; 
	NSString *query = [NSString stringWithString: [queryText string]];                
	[query autorelease];
	if(selection.length > 0){
		return [query substringWithRange: selection];
	}else{
		return query;
	}
}

- (void) setString: (NSString*) s{
	[queryText setString: s];
	[self setIsEdited: NO];
}


#pragma mark ---- init ----

- (id) initWithConnection: (ConnectionController*) c{
	if (self = [super init]){
		connection = c;
		[connection retain];
		return self;
	}             
	return nil;
}

- (void) dealloc{         
	[connection release];
	[queryResult release];
	[super dealloc];	
}

- (NSString*) nibName{
	return @"QueryView";
}    

- (void) setNoWrapToTextView: (NSTextView*) tv{ 
	[[tv textContainer] setContainerSize:NSMakeSize(FLT_MAX, FLT_MAX)];
	[[tv textContainer] setWidthTracksTextView:NO];
	[tv setHorizontallyResizable:YES];
	[tv setMaxSize:NSMakeSize(FLT_MAX, FLT_MAX)];                                             
	[tv setFont:[NSFont userFixedPitchFontOfSize:[NSFont smallSystemFontSize]]];
}

- (void) awakeFromNib{
	queryTextLineNumberView = [[MarkerLineNumberView alloc] initWithScrollView:queryTextScrollView];
  [queryTextScrollView setVerticalRulerView:queryTextLineNumberView];
  [queryTextScrollView setHasHorizontalRuler:NO];
  [queryTextScrollView setHasVerticalRuler:YES];
  [queryTextScrollView setRulersVisible:YES];  
  	
	syntaxColoringTextView = queryText;
	[self syntaxColoringInit];
	[self showResultsCount];
	[self setIsEdited: NO];  
  
  //proportional font to all text views
	[queryText setFont:[NSFont userFixedPitchFontOfSize:[NSFont smallSystemFontSize]]];                                     
 	[messagesTextView setFont:[NSFont userFixedPitchFontOfSize:[NSFont smallSystemFontSize]]];
	[textResultsTextView setFont:[NSFont userFixedPitchFontOfSize:[NSFont smallSystemFontSize]]];
	
	[self setNoWrapToTextView:messagesTextView];
	[self setNoWrapToTextView:queryText];
	[self setNoWrapToTextView:textResultsTextView];
	
	[self splitViewDidResizeSubviews: nil];  
	[self splitResultsAndQueryTextEqualy: nil];
	lastResultsTabIndex	= 0;
	[self maximizeQueryText: nil];
}      

#pragma mark ---- positioning ----

- (void)splitViewDidResizeSubviews:(NSNotification *)aNotification{		
	NSRect frame = [resultsTabView frame];
	frame.size.height = [resultsContentView frame].size.height - 35;	
	frame.origin.x = 0;
	frame.origin.y = 0;
	if (frame.size.height >= 0){
		[resultsTabView setFrame: frame];				
	}
}


#pragma mark ---- tab navigation ----

- (IBAction)resultsMessagesSegmentControlClicked:(id)sender
{
	[resultsTabView selectTabViewItemAtIndex: [sender selectedSegment]];
}                                      

- (void)tabView:(NSTabView *)tabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem{
	int selectedIndex = [resultsTabView indexOfTabViewItem: tabViewItem];	
	[resultsMessagesSegmentedControll setSelectedSegment: selectedIndex];  
	[resultsCountBox setHidden: selectedIndex != 0];
	[self showResultsCount];
	if (selectedIndex == 0){
		[tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
	}
	[self updateNextKeyViewRing];                      
	if (selectedIndex != 2)
		lastResultsTabIndex = selectedIndex;
}  
                             
- (void) updateNextKeyViewRing{
	[messagesTextView setNextKeyView: [connection outlineView]];
	[resultsTableView setNextKeyView: [connection outlineView]];
	[textResultsTextView setNextKeyView: [connection outlineView]];
}             

- (void) showResultsCount{ 	
	[resultsCountBox setHidden: !([queryResult	resultsCount] > 1 && [resultsTabView indexOfTabViewItem: [resultsTabView selectedTabViewItem]] == 0)];	
	if (![resultsCountBox isHidden]){
	  [resultsCountLabel setStringValue: [NSString stringWithFormat: @"Results %d of %d", [queryResult currentResultIndex] + 1, [queryResult	resultsCount]]];
	}	
}

- (IBAction) showResults: (id) sender{               
	[resultsTabView	selectTabViewItemAtIndex: 0];
}

- (IBAction) showTextResults: (id) sender{
	[resultsTabView	selectTabViewItemAtIndex: 1];
}

- (IBAction) showMessages: (id) sender{
	[resultsTabView	selectTabViewItemAtIndex: 2];
}                                      

- (IBAction) nextResultsTab: (id) sender{
	[resultsTabView selectNextTabViewItem: sender];
}

- (IBAction) previousResultsTab: (id) sender{
	[resultsTabView selectPreviousTabViewItem: sender];
}

- (IBAction) nextResult: (id) sender {
	if ([queryResult	nextResult])
		[self reloadResults];  
}

- (IBAction) previousResult: (id) sender {
	if ([queryResult	previousResult])
		[self reloadResults];
}

#pragma mark ---- navigation goto control ---- 

- (IBAction) goToQueryText: (id) sender{
	[sender makeFirstResponder: queryText];
}
                                        
- (IBAction) goToResults: (id) sender{         
	[self showResults: sender];
	[sender makeFirstResponder: resultsTableView];
}

- (IBAction) goToMessages: (id) sender{
	[self showMessages: sender];
	[sender makeFirstResponder: messagesTextView];
}
       
#pragma mark ---- navigation maximize view ---- 

- (IBAction) splitResultsAndQueryTextEqualy: sender{
	[splitView setPosition: [splitView frame].size.height / 2 ofDividerAtIndex:0];
}

- (IBAction) maximizeResults: sender{
	[splitView setPosition: 1 ofDividerAtIndex:0];
}

- (IBAction) maximizeQueryText: sender{
	[splitView setPosition: ([splitView frame].size.height - 20) ofDividerAtIndex:0];
}
                                     
#pragma mark ---- show results ----

- (void) setResult: (QueryResult*) r{     
	executingConnection = nil;
	if (!r) return;
	
	[queryResult release];
	queryResult = r;
	[queryResult retain]; 
	                   
	if ([queryResult database])
		[self setDatabase: [queryResult database]];		
		
	[self reloadResults];
	[self reloadMessages];
	[textResultsTextView setString: [queryResult resultsInText]];
	
	if ([queryResult hasResults]){           
		if ([splitView isSubviewCollapsed: resultsContentView]){
			[self splitResultsAndQueryTextEqualy: nil];
		}		
		[resultsTabView selectTabViewItemAtIndex: lastResultsTabIndex];
		//[self showResults: nil];
	}else {
		[self showMessages: nil];
	}
		
	[self setIsProcessing: NO];
}                                       
        
- (void) reloadResults{
 	[self removeAllColumns];							
	[self addColumns];							
	[tableView reloadData];
	[self showResultsCount];
}

-(void) reloadMessages{
	[messagesTextView setString:@""];
	for(id message in [queryResult messages]){			
		[messagesTextView insertText: message];	
	}   
	[messagesTextView insertText: @"\n"];			
} 

- (void) addColumns{
	NSArray *columns = [queryResult columns];
	for(int i=0; i<[columns count]; i++){
		[self addColumn: [columns objectAtIndex: i]];		
	}
}

- (void) addColumn:(ColumnMetadata*) meta{
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

- (void) removeAllColumns{
	int count = [[tableView tableColumns] count];
	for(int i = count - 1; i >= 0; i--){
		NSTableColumn *col = [[tableView tableColumns] objectAtIndex: i];
		[tableView removeTableColumn: col];
	}
}
                              
#pragma mark ---- tableview delegate ----

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView{	
	return [queryResult rowsCount];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {		
	return [queryResult rowValue: rowIndex: [[aTableColumn identifier] integerValue]];
}

- (void) textDidChange: (NSNotification *) aNotification{
	[self setIsEdited: TRUE];
}

#pragma mark ---- save open ----

- (IBAction) saveDocument: (id) sender {
	[self saveQuery: NO];
}                          

- (IBAction) saveDocumentAs: (id) sender {
	[self saveQuery: YES];
}                          

- (BOOL) saveQuery:(bool) saveAs{		
	if (!fileName || saveAs){
		NSSavePanel *panel = [NSSavePanel savePanel];  
		[panel setExtensionHidden: NO];
		if (fileName)
			[panel setNameFieldStringValue: [fileName lastPathComponent]];
		else
		  if (name)	  	                                                
				[panel setNameFieldStringValue: name];
		[panel setRequiredFileType:@"sql"];
		if (![panel runModal] == NSOKButton) {
			return NO;
		}                                                                      
		[self setFileName: [panel filename]];  
		[self setName: [[fileName lastPathComponent] stringByDeletingPathExtension]];		
	}	
	[[queryText string] writeToFile: fileName atomically:YES encoding:NSUTF8StringEncoding error:NULL];		
	[self setIsEdited: NO];            	
	return YES;
}

- (void) openFile: (NSString*) fn{
	[self setFileName: fn];                       
	[self setName: [[fileName lastPathComponent] stringByDeletingPathExtension]];
	NSString *fileContents = [NSString stringWithContentsOfFile:fileName encoding:NSUTF8StringEncoding error:NULL];
	[queryText setString: fileContents];
	[self setIsEdited: NO];
}

#pragma mark ---- execute ----

- (IBAction) cancelExecutingQuery: (id) sender {
	if (executingConnection){
		NSLog(@"canceling current query execution");
		[executingConnection setCancelQuery];
		[self setIsProcessing: NO];
		[messagesTextView insertText: @"\nQuery canceled\n"];
	}
}

-(void) setExecutingConnection: (TdsConnection*) tdsConnection{
	executingConnection = tdsConnection;
}                                                             

- (void) keyDown:(NSEvent *)theEvent{
	NSLog(@"query received keyDown event");	
}


@end
			