#import "ConnectionController.h"

@implementation ConnectionController (DatabaseObjects)

-(void) dbObjectsFillSidebar{         
	@try{	                  
		[self fillDatabasesCombo];
		[self readDatabaseObjects];	  
	}@catch(NSException *exception){    
		NSLog(@"error in fillSidebar: %@", exception);
	}
}                         

- (void) readDatabaseObjects{
	[self executeQueryInBackground: @"exec sp_cqa_database_objects" withDatabase: @"master" returnToObject: self withSelector: @selector(setObjectsResult:)];		
	// [dbObjectsResults release];	
	// dbObjectsResults = [[tdsConnection execute: @"exec sp_cqa_database_objects"] rows];	
	// [dbObjectsResults retain];
	// 
	// [dbObjectsCache release];		
	// dbObjectsCache = [NSMutableDictionary dictionary];		
	// [dbObjectsCache retain];             
	// 
	// [outlineView reloadData];
	// [outlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
}       

- (void) setObjectsResult: (QueryResult*) queryResult{ 
	[dbObjectsResults release];	
	dbObjectsResults = [queryResult rows];	
	[dbObjectsResults retain];
	
	[dbObjectsCache release];		
	dbObjectsCache = [NSMutableDictionary dictionary];		
	[dbObjectsCache retain];             
	
	[outlineView reloadData];
	[outlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];	
}

- (void) fillDatabasesCombo{
	// NSString *query = @"select name from master.sys.databases where owner_sid != 01 and state_desc = 'ONLINE' order by name";
	// [self executeQueryInBackground: query withDatabase: @"master" returnToObject: self withSelector: @selector(setDatabasesResult:)];	
	[databasesPopUp removeAllItems];          
	QueryResult *queryResult = [tdsConnection execute: @"select name from master.sys.databases where owner_sid != 01 and state_desc = 'ONLINE' order by name"];
	for(NSArray *row in [queryResult rows]){     
		NSString *title = [row objectAtIndex: 0];
		[databasesPopUp addItemWithTitle: title];
	} 
	[databasesPopUp selectItemWithTitle: [tdsConnection currentDatabase]];     
	[self databaseChanged: nil]; 
}    

- (void) setDatabasesResult: (QueryResult*) queryResult{    
	[databasesPopUp removeAllItems];	
	for(NSArray *row in [queryResult rows]){     
		NSString *title = [row objectAtIndex: 0];
		[databasesPopUp addItemWithTitle: title];
	} 
	[databasesPopUp selectItemWithTitle: [tdsConnection currentDatabase]];
	[self databaseChanged: nil];	
}

- (void) displayDefaultDatabase{
	[databasesPopUp selectItemWithTitle: [[self currentQueryController] defaultDatabase]];  
	if (![databasesPopUp selectedItem]){ 
		[self databaseChanged: nil];
	}
}   

- (void) databaseChanged:(id)sender{                  
	if ([sender titleOfSelectedItem]){
		[[self currentQueryController] setDefaultDatabase: [sender titleOfSelectedItem]];	
	}else{                                               
		NSString *dbName = [tdsConnection currentDatabase];
		if (dbName){                               
			[[self currentQueryController] setDefaultDatabase: dbName];	
	  	[databasesPopUp selectItemWithTitle: dbName];
		}
  }
}                               

-(NSArray*) dbObjectsForParent: (NSString*) parentId
{
	
	if ([dbObjectsCache objectForKey:parentId] != nil){
		NSArray *item = [dbObjectsCache objectForKey:parentId]; 
		return item;
	}
	
	NSMutableArray *selected = [NSMutableArray array];		
	//NSLog(@"searching for childs of: %@", parentId);
	
	for(int i=0; i<[dbObjectsResults count]; i++)
	{
		NSArray *row = [dbObjectsResults objectAtIndex:i];			
		if ([[row objectAtIndex:1] isEqualToString: parentId]){
			[selected addObject:row];
		}
	}		
	[dbObjectsCache setObject:selected forKey:parentId];	
	return selected;
}

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {
	NSArray *selected = [self dbObjectsForParent: (item == nil ? @"" : [item objectAtIndex:0])];
	return [selected count];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {
	return [[item objectAtIndex:3 ] isEqualToString: @"NULL"];
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item {
	NSArray *selected = [self dbObjectsForParent: (item == nil ? @"" : [item objectAtIndex:0])];
	return [selected objectAtIndex:index];
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item {
	return [item objectAtIndex:2];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldEditTableColumn:(NSTableColumn *)tableColumn item:(id)item {
	return NO;
}

- (NSArray*) selectedDbObject
{
	int row = [outlineView selectedRow];
	if( row >= 0 )
		return [outlineView itemAtRow: row];
	else
		return nil;
}     

@end
