#import "QueryController.h"

@implementation QueryController

@synthesize isEdited, isProcessing, fileName, database;

- (id) initWithConnection: (ConnectionController*) c{
	if (self = [super init]){
		connection = c;
		[connection retain];
		return self;
	}             
	return nil;
}

- (void) setIsEdited: (BOOL) value{
	if (value != isEdited){
		isEdited = value;
		[connection isEditedChanged: self];
	}
}

- (void) dealloc{         
	//[splitViewDelegate release];
	[connection release];
	[queryResult release];
	[super dealloc];	
}

- (NSString*) nibName{
	return @"QueryView";
}

- (void) awakeFromNib{
	queryTextLineNumberView = [[MarkerLineNumberView alloc] initWithScrollView:queryTextScrollView];
  [queryTextScrollView setVerticalRulerView:queryTextLineNumberView];
  [queryTextScrollView setHasHorizontalRuler:NO];
  [queryTextScrollView setHasVerticalRuler:YES];
  [queryTextScrollView setRulersVisible:YES];  
  [queryText setFont:[NSFont userFixedPitchFontOfSize:[NSFont smallSystemFontSize]]];  
	
	syntaxColoringTextView = queryText;
	[self syntaxColoringInit];
	[self showResultsCount];
	[self setIsEdited: NO];  
                                     
 	[messagesTextView setFont:[NSFont userFixedPitchFontOfSize:[NSFont smallSystemFontSize]]];
	
	//set no-wrap to messagesTextView
	[[messagesTextView textContainer] setContainerSize:NSMakeSize(FLT_MAX, FLT_MAX)];
	[[messagesTextView textContainer] setWidthTracksTextView:NO];
	[messagesTextView setHorizontallyResizable:YES];
	[messagesTextView setMaxSize:NSMakeSize(FLT_MAX, FLT_MAX)];
	
	//set no-wrap to queryText view
	[[queryText textContainer] setContainerSize:NSMakeSize(FLT_MAX, FLT_MAX)];
	[[queryText textContainer] setWidthTracksTextView:NO];
	[queryText setHorizontallyResizable:YES];
	[queryText setMaxSize:NSMakeSize(FLT_MAX, FLT_MAX)]; 
	
	[self splitViewDidResizeSubviews: nil];
}

- (IBAction)resultsMessagesSegmentControlClicked:(id)sender
{
	[resultsTabView selectTabViewItemAtIndex: [sender selectedSegment]];
}

- (IBAction) showResults: (id) sender{
	[resultsTabView	selectTabViewItemAtIndex: 0];
	[resultsMessagesSegmentedControll setSelectedSegment:0];
  [self showResultsCount];                     
	[tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
	[self updateNextKeyViewRing];
}

- (IBAction) showMessages: (id) sender{
	[resultsTabView	selectTabViewItemAtIndex: 1];
	[resultsMessagesSegmentedControll setSelectedSegment:1];
	[self showResultsCount];
	[self updateNextKeyViewRing];
}

- (void) showResultsCount{
	[resultsCountBox setHidden: ([queryResult	resultsCount] < 2)];	
	if (![resultsCountBox isHidden]){
	  [resultsCountLabel setStringValue: [NSString stringWithFormat: @"Results %d of %d", [queryResult currentResultIndex] + 1, [queryResult	resultsCount]]];
	}	
}

- (IBAction) nextResult: (id) sender {
	if ([queryResult	nextResult])
		[self reloadResults];  
}

- (IBAction) previousResult: (id) sender {
	if ([queryResult	previousResult])
		[self reloadResults];
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

- (void) setResult: (QueryResult*) r{     
	if (!r) return;
	
	[queryResult release];
	queryResult = r;
	[queryResult retain]; 
	                   
	if ([queryResult database])
		[self setDatabase: [queryResult database]];		
		
	[self reloadResults];
	[self reloadMessages];
	if ([queryResult hasResults])
		[self showResults: nil];
	else {
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
	[messagesTextView insertText: [queryResult resultsInText]];	
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

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView{	
	return [queryResult rowsCount];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {		
	return [queryResult rowValue: rowIndex: [[aTableColumn identifier] integerValue]];
}

- (void) textDidChange: (NSNotification *) aNotification{
	[self setIsEdited: TRUE];
}

- (IBAction) saveDocument: (id) sender {
	[self saveQuery];
}                          

- (IBAction) openDocument:(id)sender {      
	[self openQuery];
} 

- (BOOL) saveQuery{		
	if (!fileName){
		NSSavePanel *panel = [NSSavePanel savePanel];
		[panel setRequiredFileType:@"sql"];
		if (![panel runModal] == NSOKButton) {
			return NO;
		}
		[self setFileName: [panel filename]];
	}	
	[[queryText string] writeToFile: fileName atomically:YES encoding:NSUTF8StringEncoding error:NULL];		
	[self setIsEdited: NO];            	
	return YES;
}

- (void) openQuery {
	NSOpenPanel *panel = [NSOpenPanel openPanel];
	if ([panel runModal] == NSOKButton) {
		[self setFileName: [panel filename]];
		NSString *fileContents = [NSString stringWithContentsOfFile:fileName encoding:NSUTF8StringEncoding error:NULL];
		[queryText setString: fileContents];
		[self setIsEdited: NO];
	}
}

- (void) setString: (NSString*) s{
	[queryText setString: s];
	[self setIsEdited: NO];
}

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
       
- (void) updateNextKeyViewRing{
	[messagesTextView setNextKeyView: [connection outlineView]];
	[resultsTableView setNextKeyView: [connection outlineView]];
}             

- (void)splitViewDidResizeSubviews:(NSNotification *)aNotification{		
	NSRect frame = [resultsTabView frame];
	frame.size.height = [resultsContentView frame].size.height - 35;	
	frame.origin.x = 0;
	frame.origin.y = 0;
	if (frame.size.height >= 0){
		[resultsTabView setFrame: frame];				
	}
	//NSLog(@"splitViewDidResizeSubviews resultsContentView: %f resultsTabView: %f splitView: %f", [resultsContentView frame].size.height, [resultsTabView frame].size.height,  [splitView frame].size.height);
}

- (IBAction) splitResultsAndQueryTextEqualy: sender{
	[splitView setPosition: [splitView frame].size.height / 2 ofDividerAtIndex:0];
}

- (IBAction) maximizeResults: sender{
	[splitView setPosition: 1 ofDividerAtIndex:0];
}

- (IBAction) maximizeQueryText: sender{
	[splitView setPosition: ([splitView frame].size.height - 20) ofDividerAtIndex:0];
}

@end
			