#import <Cocoa/Cocoa.h>
#import "QueryController.h"
#import "CredentialsController.h"
#import "TdsConnection.h"

@class CredentialsController;

@interface ConnectionController : NSWindowController {
	
	IBOutlet NSTabView *queryTabs;    		
	IBOutlet NSOutlineView *outlineView;
	
	CredentialsController *credentials;	
	int queryTabsCounter;
	TdsConnection *currentConnection;
	
	NSArray *dbObjectsResults;	
	NSMutableDictionary *dbObjectsCache;
}

- (QueryController*) currentQueryController;

- (IBAction) newTab: (id) sender;
- (IBAction) nextTab: (id) sender;
- (IBAction) previousTab: (id) sender;

- (BOOL) windowShouldClose: (id) sender;

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

@end

@interface ConnectionController (DatabaseObjects)

-(void) dbObjectsFillSidebar;

@end
