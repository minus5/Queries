#import "ConnectionController.h"

@implementation ConnectionController (DatabaseObjects)

-(void) dbObjectsFillSidebar{         
	@try{	
		[currentConnection execute: @"exec sp_cqa_database_objects"];
		[dbObjectsResults release];
		dbObjectsResults = [currentConnection rows];
		[dbObjectsResults retain];
		[dbObjectsCache release];		
		dbObjectsCache = [NSMutableDictionary dictionary];		
		[dbObjectsCache retain];
		[outlineView reloadData];
	}@catch(NSException *exception){    
		NSLog(@"error in fillSidebar: %@", exception);
	}
}

-(NSArray*) dbObjectsForParent: (NSString*) parentId
{
	
	if ([dbObjectsCache objectForKey:parentId] != nil){
		NSArray *item = [dbObjectsCache objectForKey:parentId]; 
		return item;
	}
	
	NSMutableArray *selected = [NSMutableArray array];		
	NSLog(@"searching for childs of: %@", parentId);
	
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
