#import "ConnectingController.h"

@implementation ConnectingController

- (NSString*) windowNibName{
	return @"Connecting";
}           

- (void) awakeFromNib{ 
	[progress setUsesThreadedAnimation: YES];
	[progress startAnimation: nil];
	[label setStringValue: labelString];
}                   

- (id) initWithLabel: (NSString*) l{
	if (self = [super init]){
		labelString = l;
	}
	return self;
}

- (IBAction) close: (id)sender{
	//[[self window] orderOut: self];              
	[NSApp endSheet: [self window] returnCode: NSRunAbortedResponse];
}

@end