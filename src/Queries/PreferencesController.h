#import <Cocoa/Cocoa.h>

extern NSString *const QueriesConnectionDefaults;
extern NSString *const QueriesLoginTimeout;
extern NSString *const QueriesQueryTimeout;

@interface PreferencesController : NSWindowController { 	
	IBOutlet NSTextView *connectionDefaults;
	IBOutlet NSTextField *queryTimeout;
  IBOutlet NSTextField *loginTimeout;
}                                 
                                                  
- (void) readDefaults;
- (void) saveDefaults;
- (IBAction) resetDefaults:(id)sender;

@end
