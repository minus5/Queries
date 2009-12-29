#import <Cocoa/Cocoa.h>
#import "Constants.h"

@interface PreferencesController : NSWindowController { 	
	//IBOutlet NSTextView *connectionDefaults;
	IBOutlet NSTextField *queryTimeout;
  IBOutlet NSTextField *loginTimeout;
	IBOutlet NSButton *groupBySchema;
}                                 
                                                  
- (void) readDefaults;
- (void) saveDefaults;              
- (IBAction)checkboxClicked:(id)sender;
- (IBAction) resetDefaults:(id)sender; 
- (IBAction) close: (id)sender;

@end
