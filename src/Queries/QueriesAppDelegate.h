#import <Cocoa/Cocoa.h>
#import "ConnectionController.h"
#import "QueryController+SyntaxHighlight.h"

@interface QueriesAppDelegate : NSObject <NSApplicationDelegate> {
    NSWindow *window;
}

@property (assign) IBOutlet NSWindow *window;

- (IBAction) newDocument: (id) sender;

@end
