#import "QueryController.h"

@implementation QueryController

@synthesize isEdited, isProcessing, fileName, database, name, status;
                           
#pragma mark ---- properties ----

- (void) processingStarted{
	[self setIsProcessing: YES];          
	
 	[self setStatus: @"Executing query..."];
	[messagesTextView insertText: @"\nExecuting query...\n"];
}

-(BOOL) isEdited
{
    return isEdited;
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
	if(selection.length > 0){
		return [query substringWithRange: selection];
	}else{
		return query;
	}
}


- (NSString*) queryParagraphString{          
	NSRange selection = [queryText selectedRange]; 
	NSString *query = [NSString stringWithString: [queryText string]];                  
  NSRange currentLine = [query lineRangeForRange: selection];
  
  NSRange startParagraph = currentLine;
  NSRange endParagraph = currentLine;
  while(startParagraph.location > 0 && startParagraph.length > 1){
    startParagraph = [query lineRangeForRange: NSMakeRange(startParagraph.location - 1, 1)];
  }
  while((endParagraph.location + endParagraph.length) < [query length] && endParagraph.length > 1){
    endParagraph = [query lineRangeForRange: NSMakeRange((endParagraph.location + endParagraph.length), 1)];
  }
  
  NSRange paragraph = NSMakeRange(startParagraph.location, endParagraph.location - startParagraph.location + endParagraph.length);  
	if(paragraph.length > 1){
    //[queryText setSelectedRange: paragraph];
		return [query substringWithRange: paragraph];
	}else{
		return NULL;
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
		status = @"";		
	}             
	return self;
}

- (void) dealloc{         
	NSLog(@"[%@ dealloc]", [self class]);     
	[[NSNotificationCenter defaultCenter] removeObserver:self];   	
	[queryResult release];                       
	[dataSources release];
	
	[syntaxColoringController setDelegate: nil];
	[syntaxColoringController release];
	syntaxColoringController = nil;
	
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
}

/**
 * Scrollview delegate after the command textView's view port was changed.
 * Manily used to render line numbering.
 */
- (void)boundsDidChangeNotification:(NSNotification *)notification
{
	[queryTextScrollView display];
}

- (void) awakeFromNib{
    queryTextLineNumberView = [[NoodleLineNumberView alloc] initWithScrollView:queryTextScrollView];
    [queryTextScrollView setVerticalRulerView:queryTextLineNumberView];
    [queryTextScrollView setHasHorizontalRuler:NO];
    [queryTextScrollView setHasVerticalRuler:YES];
    [queryTextScrollView setRulersVisible:YES];  
	[queryTextScrollView setPostsBoundsChangedNotifications:YES];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(boundsDidChangeNotification:) name:NSViewBoundsDidChangeNotification object:[queryTextScrollView contentView]];
  	
	syntaxColoringController = [[UKSyntaxColoredTextViewController alloc] init];
	[syntaxColoringController setDelegate: self];
	[syntaxColoringController setView: queryText];
	
	[self setIsEdited: NO];  
  
    //proportional font to all text views
	[queryText setFont:[NSFont userFixedPitchFontOfSize:[NSFont smallSystemFontSize]]];                                     
 	[messagesTextView setFont:[NSFont userFixedPitchFontOfSize:[NSFont smallSystemFontSize]]];
	[textResultsTextView setFont:[NSFont userFixedPitchFontOfSize:[NSFont smallSystemFontSize]]];
	
	[self setNoWrapToTextView:messagesTextView];
	[self setNoWrapToTextView:queryText];
	[self setNoWrapToTextView:textResultsTextView];
	
	[self splitViewDidResize: nil];  
    spliterPosition = 0;
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
	switch(selectedIndex){
		case 0:                      
			[self resizeTablesSplitView: NO];
			if (firstTableView)
				[queryText setNextKeyView: firstTableView];
			break;
		case 1:                                                      
			[self displayTextResults];	
			[queryText setNextKeyView: textResultsTextView];
			break;
		case 2: 
			[queryText setNextKeyView: messagesTextView];
			break;
	} 
	if (selectedIndex != 2)
		lastResultsTabIndex = selectedIndex;
}

- (void) displayTextResults{
	int selectedIndex = [resultsTabView indexOfTabViewItem: [resultsTabView selectedTabViewItem]];
	if (selectedIndex == 1){
		if ([[textResultsTextView string] length] == 0){
			[textResultsTextView setString: [queryResult resultsInText]];
			[textResultsTextView setSelectedRange: NSMakeRange(0, 0)];
		}                       
	}
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
    [splitView setPosition: ([splitView frame].size.height) ofDividerAtIndex:0];
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
		[self displayTextResults];        
	}else {
		[self showMessages];
	}
    [self ensureResultsAreVisible];
		
	[self setIsProcessing: NO];
	[[ConnectionsManager sharedInstance] cleanup];
	[self setStatus: [queryResult status]];
}                                       

-(void) reloadMessages{
	[messagesTextView setString:@""];
	for(id message in [queryResult messages]){			
		[messagesTextView insertText: message];	
	}   
	[messagesTextView insertText: @"\n"];			
}

-(void) showErrorMessage: (NSString*) message{
	[messagesTextView insertText: message];		
    [self showMessages];
	[self setStatus: @"Error"];
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
	[newTableView setAllowsMultipleSelection: YES];

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
		for(int i=0; i < count; i++){
			float tableHeight = ([self minHeightForTableAtIndex: i] / minHeightOfAllTables) * allTablesHeight;
			NSView *subview = [[tablesSplitView subviews] objectAtIndex: i];
			NSRect frame;
			frame.origin.x = 0;
			frame.size.width = [tablesSplitView frame].size.width;
			frame.size.height = tableHeight;  
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
    NSArray* types = [NSArray arrayWithObject:(id) @"sql"];
		[panel setAllowedFileTypes: types];
		if (![panel runModal] == NSOKButton) {
			return NO;
		}                                                                      
		[self setFileName: [panel URL].path];  
		[self setName: [[fileName lastPathComponent] stringByDeletingPathExtension]];		
	}	
	[[queryText string] writeToFile: fileName atomically:YES encoding:NSUTF8StringEncoding error:NULL];
  [[NSDocumentController sharedDocumentController] noteNewRecentDocumentURL:[NSURL fileURLWithPath:fileName]];		
	[self setIsEdited: NO];            	
	return YES;
}

- (BOOL) openFile: (NSString*) fn{
	[self setFileName: fn];                       
	[self setName: [[fileName lastPathComponent] stringByDeletingPathExtension]];
	NSString *fileContents = [NSString stringWithContentsOfFile:fileName encoding:NSUTF8StringEncoding error:NULL];
	[queryText setString: fileContents];
	[queryText setSelectedRange: NSMakeRange(0, 0)];
	[self setIsEdited: NO];
	return YES;
}

#pragma mark ---- execute ----

- (IBAction) cancelExecutingQuery: (id) sender {
	if (executingConnection){
		NSLog(@"canceling current query execution");
		[executingConnection setCancelQuery];
		[self setIsProcessing: NO];
		[messagesTextView insertText: @"Query canceled\n"];
		[self setStatus: @"Query canceled"];
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
	return [connection objectNamesForAutocompletionInDatabase: database withSearchString: [[queryText string] substringWithRange:charRange]];					                       
}

#pragma mark syntax highlighting delegates

-(void)	textViewControllerWillStartSyntaxRecoloring: (UKSyntaxColoredTextViewController*)sender		// Show your progress indicator.
{
//	[progress startAnimation: self];
//	[progress display];
}


-(void)	textViewControllerDidFinishSyntaxRecoloring: (UKSyntaxColoredTextViewController*)sender		// Hide your progress indicator.
{
//	[progress stopAnimation: self];
//	[progress display];
}


-(void)	selectionInTextViewController: (UKSyntaxColoredTextViewController*)sender						// Update any selection status display.
							changedToStartCharacter: (NSUInteger)startCharInLine endCharacter: (NSUInteger)endCharInLine
															 inLine: (NSUInteger)lineInDoc startCharacterInDocument: (NSUInteger)startCharInDoc
							 endCharacterInDocument: (NSUInteger)endCharInDoc;
{
//	NSString*	statusMsg = nil;
//	NSImage*	selKindImg = nil;
//	
//	if( startCharInDoc < endCharInDoc )
//	{
//		statusMsg = NSLocalizedString(@"character %lu to %lu of line %lu (%lu to %lu in document).",@"selection description in syntax colored text documents.");
//		statusMsg = [NSString stringWithFormat: statusMsg, startCharInLine +1, endCharInLine +1, lineInDoc +1, startCharInDoc +1, endCharInDoc +1];
//		selKindImg = [NSImage imageNamed: @"SelectionRange"];
//	}
//	else
//	{
//		statusMsg = NSLocalizedString(@"character %lu of line %lu (%lu in document).",@"insertion mark description in syntax colored text documents.");
//		statusMsg = [NSString stringWithFormat: statusMsg, startCharInLine +1, lineInDoc +1, startCharInDoc +1];
//		selKindImg = [NSImage imageNamed: @"InsertionMark"];
//	}
//	
//	[selectionKindImage setImage: selKindImg];
//	[status setStringValue: statusMsg];
//	[status display];
}

// -----------------------------------------------------------------------------
//	stringEncoding
//		The encoding as which we will read/write the file data from/to disk.
// -----------------------------------------------------------------------------

-(NSStringEncoding)	stringEncoding
{
	return NSMacOSRomanStringEncoding;
}


/* -----------------------------------------------------------------------------
 dataRepresentationOfType:
 Save raw text to a file as MacRoman text.
 -------------------------------------------------------------------------- */

-(NSData*)	dataRepresentationOfType: (NSString*)aType
{
	//return [[textView string] dataUsingEncoding: [self stringEncoding] allowLossyConversion: YES];
	return nil;
}


/* -----------------------------------------------------------------------------
 loadDataRepresentation:ofType:
 Load plain MacRoman text from a text file.
 -------------------------------------------------------------------------- */

-(BOOL)	loadDataRepresentation: (NSData*)data ofType: (NSString*)aType
{
//	// sourceCode is a member variable:
//	if( sourceCode )
//	{
//		[sourceCode release];   // Release any old text.
//		sourceCode = nil;
//	}
//	sourceCode = [[NSString alloc] initWithData:data encoding: [self stringEncoding]]; // Load the new text.
//	
//	/* Try to load it into textView and syntax colorize it: */
//	[textView setString: sourceCode];
//	
//	// Try to get selection info if possible:
//	NSAppleEventDescriptor*  evt = [[NSAppleEventManager sharedAppleEventManager] currentAppleEvent];
//	if( evt )
//	{
//		NSAppleEventDescriptor*  param = [evt paramDescriptorForKeyword: keyAEPosition];
//		if( param )		// This is always false when Xcode calls us???
//		{
//			NSData*					data = [param data];
//			struct SelectionRange   range;
//			
//			memmove( &range, [data bytes], sizeof(range) );
//			
//			if( range.lineNum >= 0 )
//				[syntaxColoringController goToLine: range.lineNum +1];
//			else
//				[syntaxColoringController goToRangeFrom: range.startRange toChar: range.endRange];
//		}
//	}
	
	return YES;
}


/* -----------------------------------------------------------------------------
 toggleAutoSyntaxColoring:
 Action for menu item that toggles automatic syntax coloring on and off.
 -------------------------------------------------------------------------- */

-(IBAction)	toggleAutoSyntaxColoring: (id)sender
{
	[syntaxColoringController toggleAutoSyntaxColoring: sender];
}


/* -----------------------------------------------------------------------------
 toggleMaintainIndentation:
 Action for menu item that toggles indentation maintaining on and off.
 -------------------------------------------------------------------------- */

-(IBAction)	toggleMaintainIndentation: (id)sender
{
	[syntaxColoringController toggleMaintainIndentation: sender];
}


/* -----------------------------------------------------------------------------
 showGoToPanel:
 Action for menu item that shows the "Go to line" panel.
 -------------------------------------------------------------------------- */

-(IBAction) showGoToPanel: (id)sender
{
	//[gotoPanel showGoToSheet: [self windowForSheet]];
}


// -----------------------------------------------------------------------------
//	indentSelection:
//		Action method for "indent selection" menu item.
// -----------------------------------------------------------------------------

-(IBAction) indentSelection: (id)sender
{
	[syntaxColoringController indentSelection: sender];
}


// -----------------------------------------------------------------------------
//	unindentSelection:
//		Action method for "un-indent selection" menu item.
// -----------------------------------------------------------------------------

-(IBAction) unIndentSelection: (id)sender
{
	[syntaxColoringController unindentSelection: sender];
}


/* -----------------------------------------------------------------------------
 toggleCommentForSelection:
 Add a comment to the start of this line/remove an existing comment.
 -------------------------------------------------------------------------- */

-(IBAction)	toggleCommentForSelection: (id)sender
{
	[syntaxColoringController toggleCommentForSelection: sender];
}


/* -----------------------------------------------------------------------------
 validateMenuItem:
 Make sure check marks of the "Toggle auto syntax coloring" and "Maintain
 indentation" menu items are set up properly.
 -------------------------------------------------------------------------- */

-(BOOL)	validateMenuItem:(NSMenuItem*)menuItem
{
//	if( [menuItem action] == @selector(toggleAutoSyntaxColoring:) )
//	{
//		[menuItem setState: [syntaxColoringController autoSyntaxColoring]];
//		return YES;
//	}
//	else if( [menuItem action] == @selector(toggleMaintainIndentation:) )
//	{
//		[menuItem setState: [syntaxColoringController maintainIndentation]];
//		return YES;
//	}
//	else
//		return [super validateMenuItem: menuItem];
	return YES;
}


/* -----------------------------------------------------------------------------
 recolorCompleteFile:
 IBAction to do a complete recolor of the whole friggin' document.
 -------------------------------------------------------------------------- */

-(IBAction)	recolorCompleteFile: (id)sender
{
	[syntaxColoringController recolorCompleteFile: sender];
}

-(NSDictionary*)	syntaxDefinitionDictionaryForTextViewController: (id)sender{
	if (!syntaxColoringDictionary){
		syntaxColoringDictionary = [NSDictionary dictionaryWithContentsOfFile: [[NSBundle mainBundle] pathForResource: @"TSQL" ofType:@"plist"]];
	}
	[syntaxColoringDictionary retain];
	return syntaxColoringDictionary;
}

@end
			
