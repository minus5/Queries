#import <Cocoa/Cocoa.h>
#import "QueryController.h"
#import "CredentialsController.h"
#import "TdsConnection.h"    
#import <PSMTabBarControl/PSMTabBarControl.h>  
#import "QueryResult.h"                                    
#import "CreateTableScript.h"
#import "CreateProcedureScript.h"
#import "ConnectingController.h"
#import "ConnectionsManager.h"
//#import <BWToolkitFramework/BWToolkitFramework.h>  
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
	IBOutlet NSTextField *statusLabel;       
	IBOutlet NSSearchField *searchField;
	
	CredentialsController *credentials;	
	int queryTabsCounter;
	QueryController *queryController;
	
	NSArray *dbObjectsResults;     //database object for outline view, filtered
	NSArray *dbObjectsResultsAll;  //all database objects for current database
	NSArray *dbAllObjects;
	 
	NSMutableDictionary *dbObjectsCache;
  NSMutableDictionary *dbObjectsByDatabaseCache;
	NSArray *databases;       
	NSString *connectionName;
	
	NSTabViewItem *previousSelectedTabViewItem;
	ConnectingController *connectingController;

	NSThread *getConnectionThread;
}                     

@property (readonly) NSOutlineView *outlineView;

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
- (void) showConnectingSheet;
- (void) hideConnectingSheet;

- (IBAction) reloadDbObjects: (id) sender;

- (IBAction) executeQuery: (id) sender;
- (IBAction) executeQueryParagraph: (id) sender;

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
    
- (NSArray*) selectedDbObject;     
- (NSString*) databaseObjectsQuery;
- (NSArray*) dbObjectsForParent: (NSString*) parentId;
- (NSArray*) objectNamesForAutocompletionInDatabase: database withSearchString: searchString;
  
- (void) displayDatabase;
- (void) databaseChanged:(id)sender;
- (void) databaseChangedTo:(NSString*) database;
- (void) setQueryDatabaseToDefault;

- (void) setDatabasesResult: (QueryResult*) queryResult;
- (void) setObjectsResult: (QueryResult*) queryResult;
- (void) filterDatabaseObjects;

- (void) displayStatus;         

- (IBAction) searchDatabaseObjects: (id) sender; 

- (BOOL)  openFile:(NSString*) filename;
- (IBAction) closeWindow: (id) sender;   
- (void) closeWindowAlertEnded:(NSAlert *) alert code:(int) choice context:(void *) v;
- (void) showException: (NSException*) e;
@end
