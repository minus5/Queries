#import <Cocoa/Cocoa.h>


extern NSString *const QueriesConnectionDefaults;

@interface PreferencesController : NSWindowController { 	
	IBOutlet NSTextView *connectionDefaults;
}                                 

- (IBAction) restoreConnectionDefaults:(id)sender;

@end
