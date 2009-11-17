#import <Cocoa/Cocoa.h>

@interface ConnectingController : NSWindowController {
	
	IBOutlet NSProgressIndicator *progress;
	IBOutlet NSTextField *label;
	
	NSString *labelString;
	
}                                 

- (id) initWithLabel: (NSString*) l;

@end
