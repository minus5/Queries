#import <Cocoa/Cocoa.h>
#import <ColumnMetadata.h>
#import <QueryExec.h>
#import <PSMTabBarControl/PSMTabBarControl.h>  

@class NoodleLineNumberView;

@interface CocoaQueryAnalyzerAppDelegate : NSObject <NSApplicationDelegate> {
	
	NSWindow *window;
	
	IBOutlet NSTableView  *tableView;
	IBOutlet NSOutlineView *outlineView;
	
	IBOutlet NSTextView *queryText;	
	IBOutlet NSScrollView *queryTextScrollView;
	NoodleLineNumberView	*queryTextLineNumberView;
	
	IBOutlet NSTextView *logTextView;	
	
	IBOutlet NSTextField *serverNameTextField;
	IBOutlet NSTextField *databaseNameTextField;
	IBOutlet NSTextField *userNameTextField;
	IBOutlet NSTextField *passwordTextField;	
	
	IBOutlet NSMenuItem *nextResultMenu;
	IBOutlet NSMenuItem *previousResultMenu;
		
	IBOutlet NSWindow *connectionSettingsWindow;
	
	QueryExec *queryExec;
	QueryExec *sidebarQueryExec;
	
	NSArray *dbObjectsResults;	
	NSMutableDictionary *cache;
	

	IBOutlet NSTabView *tabView;  
	IBOutlet NSTabView *tabViewResults;
	IBOutlet PSMTabBarControl *tabBarResults;
	
	int queryCounter;	
}

@property (assign) IBOutlet NSWindow *window;                                                  

//textView delegates
- (void)textDidChange:(NSNotification *)aNotification;

//tabView delegates
- (void)tabView:(NSTabView *)aTabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem;
- (void)tabView:(NSTabView *)aTabView didCloseTabViewItem:(NSTabViewItem *)tabViewItem;
- (NSString *)tabView:(NSTabView *)aTabView toolTipForTabViewItem:(NSTabViewItem *)tabViewItem;

-(void) bindResult;
-(void) removeAllColumns; 
-(void) showMessages;

-(void) addColumns;
-(void) addColumn:(ColumnMetadata*) meta;

-(IBAction) executeQuery: (id) sender;

-(IBAction) nextResult: (id) sender;
-(IBAction) previousResult: (id) sender;

-(IBAction) connect: (id) sender;

-(IBAction) connectionSettings: (id) sender;

-(IBAction) newQuery: (id) sender;
-(IBAction) previousQuery: (id) sender;
-(IBAction) nextQuery: (id) sender;
-(IBAction) closeQuery: (id) sender;
-(void) changeQuery: (QueryExec*) new;
-(QueryExec*) createQuery;
-(QueryExec*) createQueryExec;

- (void) logMessage: (NSString*) message;

-(void) saveCurrentQueryTextAndSelection;

-(void) fillSidebar;
- (NSArray*) selectedSidebarItem;

- (IBAction)openDocument:(id)sender;
- (IBAction)saveDocument:(id)sender;
- (IBAction)newDocument:(id)sender;
- (IBAction)performClose:(id)sender;
- (BOOL) saveQuery;
- (IBAction) explain: (id) sender;


-(IBAction) showResults: (id) sender;
-(IBAction) showMessages: (id) sender;	

@end
