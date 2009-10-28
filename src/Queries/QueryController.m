#import "QueryController.h"
#import "QueryController+SyntaxHighlight.h"

@implementation QueryController

- (NSString*) nibName{
	return @"QueryView";
}

- (void) awakeFromNib{
	syntaxColoringTextView = textView;
	[self syntaxColoringInit];
}

- (IBAction)resultsMessagesSegmentControlClicked:(id)sender
{
	[resultsTabView selectTabViewItemAtIndex: [sender selectedSegment]];
}

- (IBAction) showResults: (id) sender{
	[resultsTabView	selectTabViewItemAtIndex: 0];
	[resultsMessagesSegmentedControll setSelectedSegment:0];
}
- (IBAction) showMessages: (id) sender{
	[resultsTabView	selectTabViewItemAtIndex: 1];
	[resultsMessagesSegmentedControll setSelectedSegment:1];
}

@end
