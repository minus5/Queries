#import <Cocoa/Cocoa.h>
#import <ColumnMetadata.h>
#import <QueryExec.h>

@interface CocoaQueryAnalyzerAppDelegate : NSObject <NSApplicationDelegate> {
	
	NSWindow *window;
	
	IBOutlet NSTableView  *tableView;
	IBOutlet NSOutlineView *outlineView;
	
	IBOutlet NSTextView *queryText;	
	IBOutlet NSTextView *logTextView;	
	
	IBOutlet NSTextField *serverNameTextField;
	IBOutlet NSTextField *databaseNameTextField;
	IBOutlet NSTextField *userNameTextField;
	IBOutlet NSTextField *passwordTextField;	
	
	IBOutlet NSMenuItem *nextResultMenu;
	IBOutlet NSMenuItem *previousResultMenu;
	
	NSArray *results;
	NSArray *columnNames;
	NSArray *dataRows;
	
	int currentResult;
	
	IBOutlet NSWindow *connectionSettingsWindow;
	
	QueryExec *queryExec;
	
	NSMutableDictionary *cache;
	
	NSMutableArray *queries;
}

@property (assign) IBOutlet NSWindow *window;

-(void) bindResult;
-(void) setWindowTitle;
-(void) removeAllColumns;

-(void) addColumns;
-(void) addColumn:(ColumnMetadata*) meta;

-(IBAction) executeQuery: (id) sender;

-(IBAction) nextResult: (id) sender;
-(IBAction) previousResult: (id) sender;

-(IBAction) connect: (id) sender;

-(IBAction) connectionSettings: (id) sender;

-(IBAction) newQuery: (id) sender;
-(int) currentQueryIndex;
-(IBAction) previousQuery: (id) sender;
-(IBAction) nextQuery: (id) sender;
-(void) changeQuery: (QueryExec*) new;

- (void) logMessage: (NSString*) message;

-(void) saveCurrentQueryTextAndSelection;

@end
