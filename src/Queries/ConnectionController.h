#import <Cocoa/Cocoa.h>
#import "QueryController.h"
#import "CredentialsController.h"
#import "TdsConnection.h"    
#import <PSMTabBarControl/PSMTabBarControl.h>  
#import "QueryResult.h"                                    
#import "CreateTableScript.h"
#import "ConnectingController.h"
#import "ConnectionsManager.h"
#import <BWToolkitFramework/BWToolkitFramework.h>  
#import "Constants.h"
#import "RegexKitLite.h"

@class CredentialsController;
@class QueryController;
@class QueryResult;

@interface ConnectionController : NSWindowController {
	
	IBOutlet NSSplitView *splitView;
	IBOutlet NSTabView *queryTabs; 
	IBOutlet PSMTabBarControl *queryTabBar; 		
	IBOutlet NSOutlineView *outlineView;
	IBOutlet NSPopUpButton *databasesPopUp;
	IBOutlet BWInsetTextField *statusLabel;       
	IBOutlet NSSearchField *searchField;
	
	CredentialsController *credentials;	
	int queryTabsCounter;
	QueryController *queryController;
	
	NSArray *dbObjectsResults;
	NSArray *dbObjectsResultsAll;
	NSMutableDictionary *dbObjectsCache;
	NSArray *databases;       
	NSString *connectionName;
  NSString *defaultDatabase;     
	
	NSTabViewItem *previousSelectedTabViewItem;
}                     

@property (readonly) NSOutlineView *outlineView;
@property (copy) NSString *defaultDatabase;

- (TdsConnection*) tdsConnection;
- (IBAction) newTab: (id) sender;
- (QueryController*) createNewTab;
- (IBAction) nextTab: (id) sender;
- (IBAction) previousTab: (id) sender;

- (BOOL) windowShouldClose: (id) sender;
- (void) closeCurentQuery;                                                     
- (void) shouldCloseCurrentQuery;
- (void) closeAlertEnded:(NSAlert *) alert code:(int) choice context:(void *) v;
                                       
- (IBAction) changeConnection: (id) sender;
- (void) didChangeConnection: (TdsConnection*) connection;
- (void) didChangeConnection:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo;

- (IBAction) reloadDbObjects: (id) sender;

- (IBAction) executeQuery: (id) sender;    

- (int) numberOfEditedQueries;                 
- (void) isEditedChanged: (id) sender;

- (IBAction) explain: (id) sender;

- (IBAction) selectFilter: (id) sender;

- (IBAction) goToQueryText: (id) sender;                                        
- (IBAction) goToDatabaseObjects: (id) sender;
- (IBAction) goToResults: (id) sender;
- (IBAction) goToTextResults: (id) sender;
- (IBAction) goToMessages: (id) sender;
- (IBAction) showHideDatabaseObjects: sender;


- (void) readDatabaseObjects;
- (void) readDatabases;
- (void) setDatabasesQueryResult: (QueryResult*) queryResult;
- (void) clearObjectsCache;

- (void) dbObjectsFillSidebar;     
- (NSArray*) selectedDbObject;     
- (NSString*) databaseObjectsQuery;
-(NSArray*) dbObjectsForParent: (NSString*) parentId;
-(NSArray*) objectNamesForAutocompletionInDatabase: database withSearchString: searchString;
  
- (void) displayDatabase;
- (void) databaseChanged:(id)sender;
- (void) setQueryDatabaseToDefault;

- (void) setDatabasesResult: (QueryResult*) queryResult;
- (void) setObjectsResult: (QueryResult*) queryResult;
- (void) filterDatabaseObjects;

- (void) displayStatus;         

- (IBAction) searchDatabaseObjects: (id) sender;
@end
