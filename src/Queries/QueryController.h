#import <Cocoa/Cocoa.h>

@interface QueryController : NSViewController {

	IBOutlet NSTabView *resultsTabView;
	IBOutlet NSSegmentedControl *resultsMessagesSegmentedControll;
	IBOutlet NSTextView	*textView;
	
	
	//syntax coloring internals
	IBOutlet NSTextField*			syntaxColoringStatus;									// Status display for things like syntax coloring or background syntax checks.			
	NSTextView*								syntaxColoringTextView;	
	BOOL											syntaxColoringAuto;										// Automatically refresh syntax coloring when text is changed?
	BOOL											syntaxColoringMaintainIndentation;	  // Keep new lines indented at same depth as their predecessor?
	BOOL											syntaxColoringBusy;										// Set while recolorRange is busy, so we don't recursively call recolorRange.
	NSRange										syntaxColoringAffectedCharRange;
	NSString*									syntaxColoringReplacementString;	
	NSUndoManager							*syntaxColoringUndoManger;
	NSDictionary							*syntaxColoringDictionary;
	
}

- (IBAction) resultsMessagesSegmentControlClicked:(id)sender;

- (IBAction) showResults: (id) sender;
- (IBAction) showMessages: (id) sender;

@end
