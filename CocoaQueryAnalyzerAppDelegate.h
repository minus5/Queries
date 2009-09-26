#import <Cocoa/Cocoa.h>
#import <ColumnMetadata.h>
#import <QueryExec.h>

@interface CocoaQueryAnalyzerAppDelegate : NSObject <NSApplicationDelegate> {
	
	NSWindow *window;
	
	IBOutlet NSTableView  *tableView;
	
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
}

@property (assign) IBOutlet NSWindow *window;

-(NSString*) query;

-(void) bindResult;

-(void)removeAllColumns;

-(void) addColumns;

-(void) addColumn:(ColumnMetadata*) meta;

-(IBAction) executeQuery: (id) sender;

-(IBAction) nextResult: (id) sender;

-(IBAction) previousResult: (id) sender;

-(IBAction) connect: (id) sender;

-(IBAction) connectionSettings: (id) sender;

- (void) logMessage: (NSString*) message;

@end
