#import <Cocoa/Cocoa.h>

@interface QueryController : NSViewController {

	IBOutlet NSTabView *resultsTabView;
	IBOutlet NSSegmentedControl *resultsMessagesSegmentedControll;
	
}

- (IBAction)resultsMessagesSegmentControlClicked:(id)sender;

- (IBAction) showResults: (id) sender;
- (IBAction) showMessages: (id) sender;

@end
