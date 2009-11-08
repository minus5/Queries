#import <Cocoa/Cocoa.h>
#import "ConnectionController.h"

@interface QueriesAppDelegate : NSObject <NSApplicationDelegate> {
    NSWindow *window;                              
		NSMutableArray *connections;
}

@property (assign) IBOutlet NSWindow *window;

- (IBAction) newDocument: (id) sender;             
- (int) numberOfEditedQueries;
- (NSApplicationTerminateReply) applicationShouldTerminate:(NSApplication *) sender;
+ (NSString*) sqlFileContent: (NSString*) queryFileName;

@end
