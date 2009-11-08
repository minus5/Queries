#import "ConnectionController.h"

@implementation ConnectionController (DatabaseObjects)

-(void) dbObjectsFillSidebar{         
	@try{	       
		[self fillDatabasesCombo];
		[self databaseObjectsQuery];               				
		[self readDatabaseObjects];	  
	}@catch(NSException *exception){    
		NSLog(@"error in fillSidebar: %@", exception);
	}
}                         

- (void) readDatabaseObjects{        
	[dbObjectsResults release];	
	dbObjectsResults = nil;
	[outlineView reloadData];
		
	[self executeQueryInBackground: [self databaseObjectsQuery]//[self queryFileContents: @"database_objects"]
		withDatabase: @"master" 
		returnToObject: self
		withSelector: @selector(setObjectsResult:)];		
}

- (NSString*) databaseObjectsQuery{
	NSMutableString *query = [NSMutableString stringWithString:[self queryFileContents: @"objects_start"]];
	[query appendFormat: @"\n\n"];
	for(id db in databases){
		[query appendFormat: @"use %@\n\n", db];
		[query appendFormat: @"%@\n", [self queryFileContents: @"objects_in_database"]];
	} 	
	[query appendFormat: @"%@\n", [self queryFileContents: @"objects_end"]];
	return query;
}

- (NSString*) queryFileContents: (NSString*) queryFileName{
	NSString *query = [NSString stringWithContentsOfFile: 
		[[NSBundle mainBundle] pathForResource: queryFileName ofType:@"sql"]
		encoding: NSUTF8StringEncoding
		error: nil
		];
	return query;
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
	NSMutableArray *dbs = [NSMutableArray array];
	QueryResult *queryResult = [tdsConnection execute: @"select name from master.sys.databases where state_desc = 'ONLINE' and (owner_sid != 01 or name = 'master') order by name"];	
	if (queryResult){         
		[databasesPopUp removeAllItems];
		for(NSArray *row in [queryResult rows]){     
			NSString *title = [row objectAtIndex: 0];
			[dbs addObject: title];
			[databasesPopUp addItemWithTitle: title];
		} 
		[databasesPopUp selectItemWithTitle: [tdsConnection currentDatabase]];     
		[self databaseChanged: nil]; 
	}       
	[databases release];
	databases = dbs;
	[databases retain]; 
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

- (void) displayDatabase{
	[databasesPopUp selectItemWithTitle: [queryController database]];  
	if (![databasesPopUp selectedItem]){ 
		[self setQueryDatabaseToDefault];
	}
}                                               

- (void) setQueryDatabaseToDefault{
		if (tdsConnection){
			NSString *dbName = [tdsConnection currentDatabase];
			if (dbName && [databasesPopUp itemWithTitle: dbName]){ 
				[queryController setDatabase: dbName];
			}
		}
}

- (void) databaseChanged:(id)sender{                              
	[queryController setDatabase: [sender titleOfSelectedItem]];	
}                               

-(NSArray*) dbObjectsForParent: (NSString*) parentId
{	
	if ([dbObjectsCache objectForKey:parentId] != nil){
		NSArray *item = [dbObjectsCache objectForKey:parentId]; 
		return item;
	}	
	NSMutableArray *selected = [NSMutableArray array];		
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
