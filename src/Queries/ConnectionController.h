#import <Cocoa/Cocoa.h>
#import "QueryController.h"
#import "CredentialsController.h"
#import "TdsConnection.h"    
#import <PSMTabBarControl/PSMTabBarControl.h>  
#import "QueryResult.h"                                    
#import "CreateTableScript.h"

@class CredentialsController;
@class QueryController;
@class QueryResult;

@interface ConnectionController : NSWindowController {
	
	IBOutlet NSTabView *queryTabs; 
	IBOutlet PSMTabBarControl *queryTabBar; 		
	IBOutlet NSOutlineView *outlineView;
	IBOutlet NSPopUpButton *databasesPopUp;
	
	CredentialsController *credentials;	
	int queryTabsCounter;
	TdsConnection *tdsConnection;                       
	QueryController *queryController;
	
	NSArray *dbObjectsResults;	
	NSMutableDictionary *dbObjectsCache;
}                     

@property (readonly) NSOutlineView *outlineView;

- (IBAction) newTab: (id) sender;
- (QueryController*) createNewTab;
- (IBAction) nextTab: (id) sender;
- (IBAction) previousTab: (id) sender;

- (BOOL) windowShouldClose: (id) sender;
- (void) closeCurentQuery;                                                     
- (void) shouldCloseCurrentQuery;
-(void) closeAlertEnded:(NSAlert *) alert code:(int) choice context:(void *) v;
                                       
- (IBAction) changeConnection: (id) sender;
- (void) didChangeConnection: (TdsConnection*) connection;

-(IBAction) reloadDbObjects: (id) sender;

-(IBAction) executeQuery: (id) sender;    
- (void) executeQueryInBackground: (NSString*) query withDatabase: (NSString*) database returnToObject: (id) receiver withSelector: (SEL) selector;

- (int) numberOfEditedQueries;                 
- (void) isEditedChanged: (id) sender;

-(IBAction) explain: (id) sender;

- (IBAction) goToQueryText: (id) sender;                                        
- (IBAction) goToDatabaseObjects: (id) sender;
- (IBAction) goToResults: (id) sender;
- (IBAction) goToMessages: (id) sender;

@end

@interface ConnectionController (DatabaseObjects)

- (NSString*) queryFileContents: (NSString*) queryFileName;
- (void) readDatabaseObjects;
- (void) fillDatabasesCombo;
- (void) dbObjectsFillSidebar;     
- (NSArray*) selectedDbObject;     
   
- (void) displayDatabase;
- (void) databaseChanged:(id)sender;
- (void) setQueryDatabaseToDefault;

- (void) setDatabasesResult: (QueryResult*) queryResult;
- (void) setObjectsResult: (QueryResult*) queryResult;

@end
