#import <Cocoa/Cocoa.h>
#import "QueryController.h"
#import "CredentialsController.h"
#import "QueryController+SyntaxHighlight.h"

@class CredentialsController;

@interface ConnectionController : NSWindowController {
	
	IBOutlet NSTabView *queryTabs;    		
	CredentialsController *credentials;	
	int queryTabsCounter;

}

- (QueryController*) currentQueryController;

- (IBAction) newTab: (id) sender;
- (IBAction) nextTab: (id) sender;
- (IBAction) previousTab: (id) sender;

- (BOOL) windowShouldClose: (id) sender;

- (IBAction) showResults: (id) sender;
- (IBAction) showMessages: (id) sender;

- (IBAction) changeConnection: (id) sender;
- (void) didChangeConnection: (id) newConnection;

-(IBAction) indentSelection: (id)sender;
-(IBAction) unIndentSelection: (id)sender;

@end
