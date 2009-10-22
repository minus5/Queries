#import <Cocoa/Cocoa.h>
#import <ColumnMetadata.h>
#import <QueryExec.h>
#import <PSMTabBarControl/PSMTabBarControl.h>  

#import "NoodleLineNumberView.h"
#import "NoodleLineNumberMarker.h"
#import "MarkerLineNumberView.h"

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
	int shouldTerminate;
	
	
	//syntax coloring internals
	IBOutlet NSTextField*			syntaxColoringStatus;									// Status display for things like syntax coloring or background syntax checks.			
	NSTextView*								syntaxColoringTextView;	
	BOOL											syntaxColoringAuto;										// Automatically refresh syntax coloring when text is changed?
	BOOL											syntaxColoringMaintainIndentation;	  // Keep new lines indented at same depth as their predecessor?
	BOOL											syntaxColoringBusy;										// Set while recolorRange is busy, so we don't recursively call recolorRange.
	NSRange										syntaxColoringAffectedCharRange;
	NSString*									syntaxColoringReplacementString;	
	NSUndoManager							*syntaxColoringUndoManger;
	NSDictionary							*syntaxColoringDictionary;
}

@property (assign) IBOutlet NSWindow *window;                                                  

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender;
-(void) applicationShouldTerminateAlertEnded:(NSAlert *) alert code:(int) choice context:(void *) v;
-(BOOL) hasEditedQueries;


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

-(IBAction) reloadSidebar: (id) sender;

@end
