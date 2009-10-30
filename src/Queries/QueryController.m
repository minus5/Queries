#import "QueryController.h"

@implementation QueryController

@synthesize isEdited, fileName, defaultDatabase;

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
	[connection release];
	[results release];
	[messages release];
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
}

- (IBAction)resultsMessagesSegmentControlClicked:(id)sender
{
	[resultsTabView selectTabViewItemAtIndex: [sender selectedSegment]];
}

- (IBAction) showResults: (id) sender{
	[resultsTabView	selectTabViewItemAtIndex: 0];
	[resultsMessagesSegmentedControll setSelectedSegment:0];
  [self showResultsCount];
}

- (IBAction) showMessages: (id) sender{
	[resultsTabView	selectTabViewItemAtIndex: 1];
	[resultsMessagesSegmentedControll setSelectedSegment:1];
	[self showResultsCount];
}

- (void) showResultsCount{
	[resultsCountBox setHidden: ([results count] < 2)];	
	if (![resultsCountBox isHidden]){
	  [resultsCountLabel setStringValue: [NSString stringWithFormat: @"Results %d of %d", currentResultIndex + 1, [results count]]];
	}	
}

- (IBAction) nextResult: (id) sender {
	if (currentResultIndex < [results count] - 1)
		currentResultIndex++;
	[self reloadResults];  
}

- (IBAction) previousResult: (id) sender {
	if(currentResultIndex > 0)
		currentResultIndex--;
	[self reloadResults];
}

- (NSString*) queryString{          
	NSRange selection = [queryText selectedRange]; 
	NSString *query = [queryText string];                
	if(selection.length > 0){
		return [query substringWithRange: selection];
	}else{
		return query;
	}
}    

- (void) setResults: (NSArray*) r andMessages: (NSArray*) m{
	[results release];
	[messages release];
	results = r;
	messages = m;
	[results retain];
	[messages retain];
	currentResultIndex = 0;
	[self reloadResults];
	[self reloadMessages];
	if ([self hasResults])
		[self showResults: nil];
	else {
		[self showMessages: nil];
	}

}                                       

- (BOOL) hasResults{
	return [results count] > 0;
}

- (NSArray*) columns{
	if ([self hasResults]){
		return [[results objectAtIndex:currentResultIndex] objectAtIndex: 0];
	}
	else {
		return nil;
	}
}  

-(NSArray*) rows{
	if ([self hasResults]){
		return [[results objectAtIndex:currentResultIndex] objectAtIndex: 1];
	}
	else {
		return nil;
	}
}                

- (int) rowsCount{
	if ([self hasResults]){
		return [[self rows] count];
	}
	else {
		return 0;
	} 
}

- (NSString*) rowValue: (int) rowIndex: (int) columnIndex{
	if ([self hasResults]){
		return [[[self rows] objectAtIndex:rowIndex] objectAtIndex: columnIndex]; 		
	}
	else {
		return nil;
	}
}

- (void) reloadResults{
 	[self removeAllColumns];							
	[self addColumns];							
	[tableView reloadData];
	[self showResultsCount];
}

-(void) reloadMessages{
	[logTextView setString:@""];
	for(id message in messages){			
		[logTextView insertText: message];	
	}   
	[logTextView insertText: @"\n"];		
} 

- (void) addColumns{
	NSArray *columns = [self columns];
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
	return [self rowsCount];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {		
	return [self rowValue: rowIndex: [[aTableColumn identifier] integerValue]];
}

- (void) textDidChange: (NSNotification *) aNotification{
	[self setIsEdited: TRUE];
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

@end
