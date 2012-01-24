#import <Cocoa/Cocoa.h>
#import "ConnectionController.h"       
#import "PreferencesController.h"
#import "Constants.h"

@interface QueriesAppDelegate : NSObject <NSApplicationDelegate> {
	NSWindow *window;                              
	NSMutableArray *connections;
		
	PreferencesController *preferences;
	NSString* fileToOpenOnLaunch;
}

@property (assign) IBOutlet NSWindow *window;

- (IBAction) newDocument: (id) sender;             
- (int) numberOfEditedQueries;
- (NSApplicationTerminateReply) applicationShouldTerminate:(NSApplication *) sender;
- (IBAction) userPreferences: (id) sender;
- (void) connectionWindowClosed:(ConnectionController *)controller;
- (BOOL)application:(NSApplication *)theApplication openFile:(NSString *)filename;
- (id) controllerToOpenFile;

+(void) initialize;

@end
