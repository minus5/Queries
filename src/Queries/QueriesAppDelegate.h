#import <Cocoa/Cocoa.h>
#import "ConnectionController.h"       
#import "PreferencesController.h"
#import "Constants.h"

@interface QueriesAppDelegate : NSObject <NSApplicationDelegate> {
    NSWindow *window;                              
		NSMutableArray *connections;
		
		PreferencesController *preferences;
}

@property (assign) IBOutlet NSWindow *window;

- (IBAction) newDocument: (id) sender;             
- (int) numberOfEditedQueries;
- (NSApplicationTerminateReply) applicationShouldTerminate:(NSApplication *) sender;
- (IBAction) userPreferences: (id) sender;
- (void) connectionWindowClosed:(ConnectionController *)controller;

+(void) initialize;

@end
