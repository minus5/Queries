#import <Cocoa/Cocoa.h>
#import "ColumnMetadata.h"   

#define _WINDEF_
#define TDS50 0
#include <sqlfront.h>	
#include <sybdb.h>  

@interface TableResultDatasource : NSObject <NSTableViewDataSource> {              
	NSTableView *tableView;
	NSArray *columns;
	NSArray *rows;
}

- (id) initWithTableView:(NSTableView*)t andColumns:(NSArray*) c andRows:(NSArray*) r;
- (void) bind;

- (void) addColumns;
- (void) addColumn:(ColumnMetadata*) meta;
- (void) removeAllColumns;

@end