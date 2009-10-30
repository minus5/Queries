#import <Cocoa/Cocoa.h>
#import "QueryController.h"
#import "CredentialsController.h"
#import "TdsConnection.h"    
#import <PSMTabBarControl/PSMTabBarControl.h>  

@class CredentialsController;
@class QueryController;

@interface ConnectionController : NSWindowController {
	
	IBOutlet NSTabView *queryTabs; 
	IBOutlet PSMTabBarControl *queryTabBar; 		
	IBOutlet NSOutlineView *outlineView;
	
	CredentialsController *credentials;	
	int queryTabsCounter;
	TdsConnection *currentConnection;
	
	NSArray *dbObjectsResults;	
	NSMutableDictionary *dbObjectsCache;
}

- (QueryController*) currentQueryController;

- (IBAction) newTab: (id) sender;
- (QueryController*) createNewTab;
- (IBAction) nextTab: (id) sender;
- (IBAction) previousTab: (id) sender;

- (BOOL) windowShouldClose: (id) sender;
- (void) closeCurentQuery;                                                     
- (void) shouldCloseCurrentQuery;
-(void) closeAlertEnded:(NSAlert *) alert code:(int) choice context:(void *) v;

- (IBAction) showResults: (id) sender;
- (IBAction) showMessages: (id) sender;

- (IBAction) nextResult: (id) sender;
- (IBAction) previousResult: (id) sender;

- (IBAction) changeConnection: (id) sender;
- (void) didChangeConnection: (TdsConnection*) connection;

-(IBAction) indentSelection: (id)sender;
-(IBAction) unIndentSelection: (id)sender;

-(IBAction) reloadDbObjects: (id) sender;

-(IBAction) executeQuery: (id) sender;

- (IBAction) saveDocument: (id) sender;
- (IBAction) openDocument: (id)sender;          
- (int) numberOfEditedQueries;                 
- (void) isEditedChanged: (id) sender;

-(IBAction) explain: (id) sender;

@end

@interface ConnectionController (DatabaseObjects)

-(void) dbObjectsFillSidebar;     
- (NSArray*) selectedDbObject;

@end
