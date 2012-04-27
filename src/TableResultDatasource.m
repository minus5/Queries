#import "TableResultDatasource.h"

@implementation TableResultDatasource
                                         
#pragma mark ---- init ----

- (id) initWithTableView:(NSTableView*)t andColumns:(NSArray*) c andRows:(NSArray*) r{
	if(self = [super init]){
		tableView = t;
		columns = c;
		rows = r;	
		[columns retain];
		[rows retain];
	}
	return self;
}            

- (void) bind{
	[self removeAllColumns];							
	[self addColumns];							
	[tableView reloadData]; 	
}   

- (void) dealloc{
	NSLog(@"[%@ dealloc]", [self class]);
	[columns release];
	[rows release];
	[super dealloc];
}

#pragma mark ---- tableview delegate ----

- (NSInteger) numberOfRowsInTableView:(NSTableView *)aTableView{	
	return [rows count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)rowIndex {		
	return [[rows objectAtIndex:rowIndex] objectAtIndex: [[tableColumn identifier] integerValue]];
}                                        

#pragma mark ---- add columns to NSTableView ----

- (void) addColumns{
	for(int i=0; i<[columns count]; i++){
		[self addColumn: [columns objectAtIndex: i]];		
	}
}

- (void) addColumn:(ColumnMetadata*) meta{
	NSTableColumn *column;
	column = [[NSTableColumn alloc] initWithIdentifier: meta.name];
	[tableView addTableColumn: column];	
	
	[[column headerCell] setStringValue:meta.name];
	[column setIdentifier: [NSString stringWithFormat:@"%d", meta.index ]];	
	
	//column width algoritam, nije bas najinteligentnije stvar na svijetu
	if ([meta length] > 40)  		             
		[column setWidth: 400];
	else if ([meta length] > 30)
		[column setWidth: [meta length] * 6];
	else if ([meta length] > 10)
		[column setWidth: [meta length] * 7];
	else                                   
		[column setWidth: [meta length] * 9];
	
	[[column dataCell] setFont: [NSFont fontWithName: @"Lucida Grande" size: 11.0]];
	[column setResizingMask:NSTableColumnUserResizingMask];
}

- (void) removeAllColumns{
	int count = [[tableView tableColumns] count];
	for(int i = count - 1; i >= 0; i--){
		NSTableColumn *col = [[tableView tableColumns] objectAtIndex: i];
		[tableView removeTableColumn: col];
	}
}

@end
