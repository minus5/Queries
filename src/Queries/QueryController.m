#import "QueryController.h"

@implementation QueryController
                   
- (void) dealloc{    
	[results release];
	[messages release];
	[super dealloc];	
}

- (NSString*) nibName{
	return @"QueryView";
}

- (void) awakeFromNib{
	syntaxColoringTextView = textView;
	[self syntaxColoringInit];
}

- (IBAction)resultsMessagesSegmentControlClicked:(id)sender
{
	[resultsTabView selectTabViewItemAtIndex: [sender selectedSegment]];
}

- (IBAction) showResults: (id) sender{
	[resultsTabView	selectTabViewItemAtIndex: 0];
	[resultsMessagesSegmentedControll setSelectedSegment:0];
}

- (IBAction) showMessages: (id) sender{
	[resultsTabView	selectTabViewItemAtIndex: 1];
	[resultsMessagesSegmentedControll setSelectedSegment:1];
}

- (NSString*) queryString{          
	NSRange selection = [textView selectedRange]; 
	NSString *queryText = [textView string];                
	if(selection.length > 0){
		return [queryText substringWithRange: selection];
	}else{
		return queryText;
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


@end
