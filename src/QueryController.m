#import "QueryController.h"

@implementation QueryController

@synthesize isEdited, isProcessing, fileName, database, name, status;

- (void) testCodeMirror{
    [queryEditor evaluateWebScript:@"editor.setOption('hintOptions', {tables:{neven:null, skendo:null}})"];
}

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
    
    NSNumber *somethingSelected = (NSNumber *)[queryEditor evaluateWebScript:@"editor.doc.somethingSelected()"];
    if([somethingSelected isEqual:@0]){
        //select everything
        id lines = [queryEditor evaluateWebScript:@"editor.doc.lineCount()"];
        [queryEditor evaluateWebScript:[NSString stringWithFormat:@"editor.doc.setSelection({line: 0, ch:0}, {line: %@, ch: 0})", lines]];
    }
    NSString *selection = [queryEditor evaluateWebScript:@"editor.doc.getSelection()"];
    return selection;
}


- (NSString*) queryParagraphString {
    WebScriptObject* cursorPos = [queryEditor evaluateWebScript:@"editor.doc.getCursor('anchor')"];
    NSNumber* curLine = [cursorPos valueForKey:@"line"];

    int startLine;
    int endLine;
    //find start of paragraph
    for (int l = curLine.intValue; l >= 0; l--) {
        NSString* lineVal = [queryEditor evaluateWebScript:[NSString stringWithFormat:@"editor.doc.getLine(%d)", l]];
        lineVal = [lineVal stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if (lineVal.length == 0 || l == 0) {
            startLine = l;
            break;
        }
    }
    //find end of paragraph
    NSNumber* lastLine = [queryEditor evaluateWebScript:@"editor.doc.lastLine()"];
    for (int l = curLine.intValue; l <= lastLine.integerValue; l++) {
        NSString* lineVal = [queryEditor evaluateWebScript:[NSString stringWithFormat:@"editor.doc.getLine(%d)", l]];
        lineVal = [lineVal stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if (lineVal.length == 0) {
            endLine = l;
            break;
        }
    }
    
    //make selection
    [queryEditor evaluateWebScript:[NSString stringWithFormat:@"editor.doc.setSelection({line: %d, ch:0}, {line: %d, ch: 0})", startLine, endLine]];
    NSString *selection = [queryEditor evaluateWebScript:@"editor.doc.getSelection()"];
    return selection;
}

- (void) setString: (NSString*) s{
    s = [[s componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]] componentsJoinedByString:@"\\n"];
    NSString* str = [NSString stringWithFormat:@"editor.doc.setValue(\"%@\")", s];
    [queryEditor evaluateWebScript:str];
	[self setIsEdited: NO];
}


#pragma mark ---- init ----

- (id) initWithConnection: (ConnectionController*) c{
	if (self = [super init]){
		connection = c;
		status = @"";	
        dataSources = [[NSMutableArray alloc] init];   
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
}

- (void) awakeFromNib{
    //setup webview
    NSString *bundle = [[NSBundle mainBundle] resourcePath];
    NSURL * url = [NSURL fileURLWithPath: [NSString stringWithFormat:@"%@/CodeMirror/index.html", bundle]];
    NSString *html = [NSString stringWithContentsOfURL: url encoding:NSUTF8StringEncoding error:nil];
    [sqlEditor.mainFrame loadHTMLString: html baseURL: url];
    queryEditor = [sqlEditor windowScriptObject];

    
	[self setIsEdited: NO];
   
    //proportional font to all text views
 	[messagesTextView setFont:[NSFont userFixedPitchFontOfSize:[NSFont smallSystemFontSize]]];
	[textResultsTextView setFont:[NSFont userFixedPitchFontOfSize:[NSFont smallSystemFontSize]]];
	
	[self setNoWrapToTextView:messagesTextView];
	[self setNoWrapToTextView:textResultsTextView];
	
	[self splitViewDidResize: nil];  
    spliterPosition = 0;
	lastResultsTabIndex	= 0;
	[self maximizeQueryText: nil];
	                                                               
	//key ring
	[messagesTextView setNextKeyView: [connection outlineView]];
	[textResultsTextView setNextKeyView: [connection outlineView]];	
	
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
				[sqlEditor setNextKeyView: firstTableView];
			break;
		case 1:                                                      
			[self displayTextResults];	
			[sqlEditor setNextKeyView: textResultsTextView];
			break;
		case 2: 
			[sqlEditor setNextKeyView: messagesTextView];
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
	if (!([[connection window] firstResponder] == sqlEditor)){
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
	[[connection window] makeFirstResponder: sqlEditor];
    [queryEditor evaluateWebScript:@"editor.cm.focus()"];
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
	if ([sqlEditor frame].size.height < 5){
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
	[[connection window] makeFirstResponder: sqlEditor];
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
			[sqlEditor setNextKeyView: newTableView];
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

- (float) biggerOf: (float) a andOf: (float) b
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
	
	float splitViewHeight = [self biggerOf: (minHeightOfAllTables + splitersHeight) andOf: [tablesScrollView frame].size.height];
	
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
		if ((![panel runModal]) == NSOKButton) {
			return NO;
		}                                                                      
		[self setFileName: [panel URL].path];  
		[self setName: [[fileName lastPathComponent] stringByDeletingPathExtension]];
	}	
	[[queryEditor evaluateWebScript:@"editor.doc.getValue()"] writeToFile: fileName atomically:YES encoding:NSUTF8StringEncoding error:NULL];
  [[NSDocumentController sharedDocumentController] noteNewRecentDocumentURL:[NSURL fileURLWithPath:fileName]];
	[self setIsEdited: NO];            	
	return YES;
}

- (BOOL) openFile: (NSString*) fn{
	[self setFileName: fn];                       
	[self setName: [[fileName lastPathComponent] stringByDeletingPathExtension]];
	NSString *fileContents = [NSString stringWithContentsOfFile:fileName encoding:NSUTF8StringEncoding error:NULL];
    [queryEditor evaluateWebScript:[NSString stringWithFormat:@"editor.doc.setValue('%@')", fileContents]];
    [self setString:fileContents];
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
-(void) setAutocompleteData: (NSMutableDictionary*) dict{
    NSData* data = [NSJSONSerialization dataWithJSONObject:dict options:0 error:nil];
    NSString* options = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    [queryEditor evaluateWebScript:[NSString stringWithFormat:@"editor.setOption('hintOptions', {tables:%@})", options]];
}

@end
			
