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
	}             
	return self;
}

- (void) dealloc{         
	NSLog(@"[%@ dealloc]", [self class]);     
	[[NSNotificationCenter defaultCenter] removeObserver:self];   	
	[queryResult release];                       
	[dataSources release];
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
	[self setIsEdited: NO];  
  
  //proportional font to all text views
	[queryText setFont:[NSFont userFixedPitchFontOfSize:[NSFont smallSystemFontSize]]];                                     
 	[messagesTextView setFont:[NSFont userFixedPitchFontOfSize:[NSFont smallSystemFontSize]]];
	[textResultsTextView setFont:[NSFont userFixedPitchFontOfSize:[NSFont smallSystemFontSize]]];
	
	[self setNoWrapToTextView:messagesTextView];
	[self setNoWrapToTextView:queryText];
	[self setNoWrapToTextView:textResultsTextView];
	
	[self splitViewDidResize: nil];  
	[self splitResultsAndQueryTextEqualy: nil];
	lastResultsTabIndex	= 0;
	[self maximizeQueryText: nil];
	                                                               
	//key ring
	[messagesTextView setNextKeyView: [connection outlineView]];
	[textResultsTextView setNextKeyView: [connection outlineView]];	
	
	dataSources = [[NSMutableArray alloc] init];   
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(splitViewDidResize:)
																							 name: NSSplitViewDidResizeSubviewsNotification
																						 object: splitView];
	
}      

#pragma mark ---- positioning ----

- (void) splitViewDidResize: (NSNotification *)aNotification{	
	NSRect frame = [resultsTabView frame];
	frame.size.height = [resultsContentView frame].size.height - 35;	
	frame.origin.x = 0;
	frame.origin.y = 0;
	if (frame.size.height >= 0){
		[resultsTabView setFrame: frame];				
	}  
	[self resizeTablesSplitView: NO];
}   

- (CGFloat)splitView:(NSSplitView *)sender constrainMinCoordinate:(CGFloat)proposedMin ofSubviewAt:(NSInteger)dividerIndex{
  NSView *subview = [[sender subviews] objectAtIndex: dividerIndex];
	if (sender == tablesSplitView){
		//NSLog(@"[%@ splitView:%@ constrainMinCoordinate:%f ofSubviewAt:%d [subview frame].origin.y:%f]", [self class], sender, proposedMin, dividerIndex, [subview frame].origin.y);
		return [subview frame].origin.y + 32.5;
	}        
	else
	{
		return proposedMin;
	}
} 

- (CGFloat)splitView:(NSSplitView *)sender constrainMaxCoordinate:(CGFloat)proposedMax ofSubviewAt:(NSInteger)dividerIndex{  
	if (sender == tablesSplitView){
		NSView *subview = [[sender subviews] objectAtIndex: dividerIndex + 1];  
		// NSLog(@"[%@ splitView:%@ constrainMaxCoordinate:%f ofSubviewAt:%d]", [self class], sender, proposedMax, dividerIndex);
		// NSLog(@"[subview frame].origin.x %f", [subview frame].origin.x);
		return [subview frame].origin.y + [subview frame].size.height - 32.5 - 9;
	}        
	else
	{
		return proposedMax;
	}
} 
  
#pragma mark ---- tab navigation ----

- (IBAction)resultsMessagesSegmentControlClicked:(id)sender
{
	[resultsTabView selectTabViewItemAtIndex: [sender selectedSegment]];
} 

- (void) makeResultsFirstResponder{
	int selectedIndex = [resultsTabView indexOfTabViewItem: [resultsTabView selectedTabViewItem]];	
	switch(selectedIndex){
		case 0:                      
			if (firstTableView)
				[[connection window] makeFirstResponder: firstTableView];
			break;
		case 1:
			[[connection window] makeFirstResponder: textResultsTextView];
			break;
		case 2: 
			[[connection window] makeFirstResponder: messagesTextView];
			break;
	}
}

- (void) tabView:(NSTabView *)tabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem{
	int selectedIndex = [resultsTabView indexOfTabViewItem: tabViewItem];	
	[resultsMessagesSegmentedControll setSelectedSegment: selectedIndex];  
	//[self makeResultsFirstResponder];	
	switch(selectedIndex){
		case 0:                      
			[self resizeTablesSplitView: NO];
			if (firstTableView)
				[queryText setNextKeyView: firstTableView];
			break;
		case 1:                                                      
			if ([[textResultsTextView string] length] == 0){
				[textResultsTextView setString: [queryResult resultsInText]];
			}
			[queryText setNextKeyView: textResultsTextView];
			break;
		case 2: 
			[queryText setNextKeyView: messagesTextView];
			break;
	} 
	if (selectedIndex != 2)
		lastResultsTabIndex = selectedIndex;
}  
                             
- (void) showResults{
	[resultsTabView	selectTabViewItemAtIndex: 0];
}

- (void) showTextResults{
	[resultsTabView	selectTabViewItemAtIndex: 1];
}

- (void) showMessages{
	[resultsTabView	selectTabViewItemAtIndex: 2];
}                                                                               

- (bool) lastTabSelected{
	return [resultsTabView indexOfTabViewItem: [resultsTabView selectedTabViewItem]] == [[resultsTabView tabViewItems] count] - 1;
}

- (IBAction) nextResultsTab: (id) sender{ 	
	[self ensureResultsAreVisible]; 	
	if (!([[connection window] firstResponder] == queryText)){
		if ([self lastTabSelected]){
			[resultsTabView selectFirstTabViewItem: sender];
		}else{
			[resultsTabView selectNextTabViewItem: sender];		
		}    	                                           
	}
	[self makeResultsFirstResponder];
}

#pragma mark ---- navigation goto control ----     

- (void) goToQueryText{ 
	[self ensureQueryTextIsVisible];	
	[[connection window] makeFirstResponder: queryText];
}
                                        
- (void) goToResults{         
	[self ensureResultsAreVisible];            
	[self showResults];              
	[self makeResultsFirstResponder];
}

- (void) goToTextResults{
	[self ensureResultsAreVisible];
	[self showTextResults];
	[self makeResultsFirstResponder];
}

- (void) goToMessages{       
	[self ensureResultsAreVisible];              
	[self showMessages];
	[self makeResultsFirstResponder];
}
 
- (void) ensureResultsAreVisible{    		
	if ([resultsContentView frame].size.height < 20){
		[self splitResultsAndQueryTextEqualy: nil];
	}
}  

- (void) ensureQueryTextIsVisible{
	if ([queryTextContentView frame].size.height < 5){
		[self splitResultsAndQueryTextEqualy: nil];
	}
}
      
#pragma mark ---- navigation maximize view ----       

- (IBAction) maximizeQueryResults: sender{
	switch(spliterPosition){
		case 0:
			[self maximizeResults: sender];
			break;
		case 1:
			[self splitResultsAndQueryTextEqualy: sender];
			break;
		case 2:
			[self maximizeQueryText: sender];
			break;
	}
}

- (IBAction) splitResultsAndQueryTextEqualy: sender{
	[splitView setPosition: ([splitView frame].size.height * 0.3) ofDividerAtIndex:0];
	spliterPosition = 2;
}

- (IBAction) maximizeResults: sender{
	[splitView setPosition: 0 ofDividerAtIndex:0];
	spliterPosition = 1;
	[self makeResultsFirstResponder];
}

- (IBAction) maximizeQueryText: sender{
	[splitView setPosition: ([splitView frame].size.height - 20) ofDividerAtIndex:0];
	spliterPosition = 0;             
	[[connection window] makeFirstResponder: queryText];
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
	[textResultsTextView setString: @""];
	
	if ([queryResult hasResults] && ![queryResult hasErrors]){           	  
		[resultsTabView selectTabViewItemAtIndex: lastResultsTabIndex];	 
	}else {
		[self showMessages];
	}
  if ([splitView isSubviewCollapsed: resultsContentView]){
		[self splitResultsAndQueryTextEqualy: nil];
	}
		
	[self setIsProcessing: NO];
	[[ConnectionsManager sharedInstance] cleanup];
}                                       

-(void) reloadMessages{
	[messagesTextView setString:@""];
	for(id message in [queryResult messages]){			
		[messagesTextView insertText: message];	
	}   
	[messagesTextView insertText: @"\n"];			
} 
        
- (void) reloadResults{
	[self createTablesPlaceholder];
	[self createTables]; 
	[self resizeTablesSplitView: YES];
}

- (void) createTables{  
	firstTableView = nil;	
	//clear existing
	int count = [[tablesSplitView subviews] count];
	for(int i = count-1; i>=0; i--){
		NSView *subview = [[tablesSplitView subviews] objectAtIndex: i];		
		[subview removeFromSuperview];
		[dataSources removeAllObjects];
	}               
	//add new
	NSTableView *prevoiusTableView = nil;
	for(int i=0; i<[queryResult resultsCount]; i++){
		NSTableView *newTableView = [self createTable];
		TableResultDatasource *dataSource = [[TableResultDatasource alloc] initWithTableView: newTableView andColumns: [queryResult columnsAtIndex:i] andRows: [queryResult resultAtIndex:i]];
		[dataSources addObject: dataSource];		
		[dataSource release];
		
		[newTableView setDataSource: dataSource];
		[dataSource bind];		                
		[queryResult nextResult];                               
      
    //keyRingCorection
		if (prevoiusTableView != nil){
			[prevoiusTableView setNextKeyView: newTableView];
		}
		[newTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
		[newTableView setNextKeyView: [connection outlineView]];
		prevoiusTableView = newTableView;    		                                               
		if (i==0){      
			firstTableView = newTableView;  
			[queryText setNextKeyView: newTableView];
		}
	}
}

- (NSTableView*) createTable{
  //prebaci split i table na autorelease pool
  //a i data source od tablice

	//todo - koju velicinu frame-a postaviti ovdje
	NSScrollView *newScrollView = [[NSScrollView alloc] initWithFrame: [tablesSplitView frame]];
	[newScrollView setHasVerticalScroller:YES];
	[newScrollView setHasHorizontalScroller:YES];
	[newScrollView setAutohidesScrollers: YES];		
	[newScrollView setAutoresizesSubviews:YES];
	[newScrollView setAutoresizingMask: NSViewHeightSizable | NSViewWidthSizable];
	
	NSTableView *newTableView = [[NSTableView alloc] init];
	[newTableView setAutoresizingMask: NSViewHeightSizable | NSViewWidthSizable];
	[newTableView setUsesAlternatingRowBackgroundColors: YES];
	[newTableView setGridStyleMask:NSTableViewSolidVerticalGridLineMask];
	[newTableView setRowHeight: 14];
	[newTableView setFocusRingType: NSFocusRingTypeNone];  
	[newTableView setColumnAutoresizingStyle: NSTableViewNoColumnAutoresizing];

	[newScrollView setDocumentView:newTableView];
	[tablesSplitView addSubview:newScrollView];		
	[newTableView release];
	[newScrollView release];
	
	return newTableView;
}                    

- (void) createTablesPlaceholder{    
  if (tablesScrollView)
		return;
	
	tablesScrollView = [[NSScrollView alloc] initWithFrame: [tableResultsContentView frame]];
	[tablesScrollView setHasVerticalScroller: NO];
	[tablesScrollView setHasHorizontalScroller: NO];
	[tablesScrollView setAutohidesScrollers: NO];		
	[tablesScrollView setAutoresizesSubviews: YES];
	[tablesScrollView setAutoresizingMask: NSViewHeightSizable | NSViewWidthSizable];
	
	tablesSplitView = [[NSSplitView alloc] initWithFrame: [tableResultsContentView frame]];
	[tablesSplitView setAutoresizesSubviews: NO];	
	[tablesScrollView setDocumentView: tablesSplitView];
	[tableResultsContentView addSubview: tablesScrollView];
	[tablesSplitView release];
	[tablesScrollView release];
	[tablesSplitView setDelegate: self];
}      

- (float) biggerOf: (float) a and: (float) b 
{
	if ( a > b )
		return a;
	else 
		return b;	
}   

- (void)scrollScrollViewToTop:(NSScrollView*) scrollView ;
{
	NSPoint newScrollOrigin;	
	if ([[scrollView documentView] isFlipped]) {
		newScrollOrigin=NSMakePoint(0.0,0.0);
	} else {
		newScrollOrigin=NSMakePoint(0.0,NSMaxY([[scrollView documentView] frame])-NSHeight([[scrollView contentView] bounds]));
	}	
	[[scrollView documentView] scrollPoint:newScrollOrigin];	
}

- (float) minHeightForTableAtIndex:(int)index{
	int rows = [[queryResult resultAtIndex: index] count];	
	return 32.5 + (rows > 9 ? 9 : rows) * 17.5;	
}

- (void) resizeTablesSplitView: (BOOL) andSubviews{	 
	//NSLog(@"[%@ resizeTablesSplitView:%d]", [self class], andSubviews);
	  
	int count = [[tablesSplitView subviews] count];
	float splitersHeight = (count - 1) * 9;            
	
	float minHeightOfAllTables = 0;
	for(int i = [[tablesSplitView subviews] count]-1; i>=0; i--){
		minHeightOfAllTables += [self minHeightForTableAtIndex: i];
	}
	
	float splitViewHeight = [self biggerOf: (minHeightOfAllTables + splitersHeight) and: [tablesScrollView frame].size.height];
	
	//resize split view
	[tablesScrollView setHasVerticalScroller: splitViewHeight > [tablesScrollView contentSize].height];				
	NSRect splitViewRect;
	splitViewRect.size.width = [tablesScrollView contentSize].width;
	splitViewRect.size.height = splitViewHeight;
	splitViewRect.origin.x = 0;
	splitViewRect.origin.y = [tablesScrollView contentSize].height - splitViewRect.size.height;	
	[tablesSplitView setFrame: splitViewRect];
	
	if (andSubviews){
		float allTablesHeight = splitViewHeight - splitersHeight; 
		//NSLog(@"allTablesHeight %f minHeightOfAllTables: %f", allTablesHeight, minHeightOfAllTables);
		for(int i=0; i < count; i++){
			float tableHeight = ([self minHeightForTableAtIndex: i] / minHeightOfAllTables) * allTablesHeight;
			NSView *subview = [[tablesSplitView subviews] objectAtIndex: i];
			NSRect frame;
			frame.origin.x = 0;
			//frame.origin.y = i * tableHeight + 9 * (i-1);
			frame.size.width = [tablesSplitView frame].size.width;
			frame.size.height = tableHeight;  
			//NSLog(@"resizing table %d with height %f min height %f", i, tableHeight, [self minHeightForTableAtIndex: i]);
			[subview setFrame:frame];
		}		
	}
	
	[self scrollScrollViewToTop: tablesScrollView];	
}
                             
#pragma mark ---- save open ----

- (void) textDidChange: (NSNotification *) aNotification{
	[self setIsEdited: TRUE];
}

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
      

#pragma mark ---- auto compleletioin ---- 

- (NSArray *)textView:(NSTextView *)textView completions:(NSArray *) words forPartialWordRange:(NSRange)charRange indexOfSelectedItem:(int *)index {
	NSMutableArray *result = [NSMutableArray array];
	NSString *string = [[queryText string] substringWithRange:charRange];                                          
			
	if ([string length] > 0){      		
		NSLog(@"running completion for string '%@'", string);	
		NSArray *objects = [connection dbObjectsForDatabase: database];
		NSRange r = {0, [string length]};
		for(id row in objects){
			NSString *fullTableName = [row objectAtIndex: 2];
		  NSArray *tableNameParts = [fullTableName componentsSeparatedByString:@"."]; 
			NSString *tableName = [tableNameParts objectAtIndex: 1];
		
			if (NSOrderedSame == [tableName compare:string options:NSCaseInsensitiveSearch range: r] ||
					NSOrderedSame == [fullTableName compare:string options:NSCaseInsensitiveSearch range: r]){
				[result addObject: fullTableName];
			}
		
		}	                       
	}
	return result;
}

@end
			