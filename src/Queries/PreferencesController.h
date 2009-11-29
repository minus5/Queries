#import <Cocoa/Cocoa.h>
#import "Constants.h"

@interface PreferencesController : NSWindowController { 	
	IBOutlet NSTextView *connectionDefaults;
	IBOutlet NSTextField *queryTimeout;
  IBOutlet NSTextField *loginTimeout;
}                                 
                                                  
- (void) readDefaults;
- (void) saveDefaults;
- (IBAction) resetDefaults:(id)sender;

@end
