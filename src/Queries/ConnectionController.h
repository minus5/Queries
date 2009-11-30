#import <Cocoa/Cocoa.h>
#import "QueryController.h"
#import "CredentialsController.h"
#import "TdsConnection.h"    
#import <PSMTabBarControl/PSMTabBarControl.h>  
#import "QueryResult.h"                                    
#import "CreateTableScript.h"
#import "ConnectingController.h"
#import "ConnectionsManager.h"

@class CredentialsController;
@class QueryController;
@class QueryResult;

@interface ConnectionController : NSWindowController {
	
	IBOutlet NSSplitView *splitView;
	IBOutlet NSTabView *queryTabs; 
	IBOutlet PSMTabBarControl *queryTabBar; 		
	IBOutlet NSOutlineView *outlineView;
	IBOutlet NSPopUpButton *databasesPopUp;
	
	CredentialsController *credentials;	
	int queryTabsCounter;
	QueryController *queryController;
	
	NSArray *dbObjectsResults;
	NSMutableDictionary *dbObjectsCache;
	NSArray *databases;       
	NSString *connectionName;
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

- (IBAction) reloadDbObjects: (id) sender;

- (IBAction) executeQuery: (id) sender;    
//- (void) executeQueryInBackground: (NSString*) query withDatabase: (NSString*) database returnToObject: (id) receiver withSelector: (SEL) selector;

- (int) numberOfEditedQueries;                 
- (void) isEditedChanged: (id) sender;

- (IBAction) explain: (id) sender;

- (IBAction) goToQueryText: (id) sender;                                        
- (IBAction) goToDatabaseObjects: (id) sender;
- (IBAction) goToResults: (id) sender;
- (IBAction) goToTextResults: (id) sender;
- (IBAction) goToMessages: (id) sender;
- (IBAction) showHideDatabaseObjects: sender;


- (NSString*) queryFileContents: (NSString*) queryFileName;
- (void) readDatabaseObjects;
- (void) fillDatabasesCombo;
- (void) dbObjectsFillSidebar;     
- (NSArray*) selectedDbObject;     
- (NSString*) databaseObjectsQuery;
-(NSArray*) dbObjectsForParent: (NSString*) parentId;
-(NSArray*) dbObjectsForDatabase: (NSString*) database;
   
- (void) displayDatabase;
- (void) databaseChanged:(id)sender;
- (void) setQueryDatabaseToDefault;

- (void) setDatabasesResult: (QueryResult*) queryResult;
- (void) setObjectsResult: (QueryResult*) queryResult;

@end
