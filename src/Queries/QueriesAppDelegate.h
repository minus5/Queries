#import <Cocoa/Cocoa.h>
#import "ConnectionController.h"       
#import "PreferencesController.h"
#import "Constansts.h"

@interface QueriesAppDelegate : NSObject <NSApplicationDelegate> {
    NSWindow *window;                              
		NSMutableArray *connections;
		
		PreferencesController *preferences;
}

@property (assign) IBOutlet NSWindow *window;

- (IBAction) newDocument: (id) sender;             
- (int) numberOfEditedQueries;
- (NSApplicationTerminateReply) applicationShouldTerminate:(NSApplication *) sender;
+ (NSString*) sqlFileContent: (NSString*) queryFileName;
- (IBAction) userPreferences: (id) sender;

+(NSString*) connectionDefaults;
+(void) initialize;

@end
