#import <Cocoa/Cocoa.h>
#import "ColumnMetadata.h"

#import "NoodleLineNumberView.h"
#import "NoodleLineNumberMarker.h"
#import "MarkerLineNumberView.h"
#import "ConnectionController.h"

@class NoodleLineNumberView;
@class ConnectionController;

#define _WINDEF_
#define TDS50 0
#include <sqlfront.h>	
#include <sybdb.h>

@interface QueryController : NSViewController {

	IBOutlet NSTabView *resultsTabView;
	IBOutlet NSSegmentedControl *resultsMessagesSegmentedControll;
	IBOutlet NSTextView	*queryText;
	IBOutlet NSTextView	*logTextView;
	IBOutlet NSTableView *tableView;
	IBOutlet NSBox *resultsCountBox;
	IBOutlet NSTextField *resultsCountLabel;
	
	IBOutlet NSScrollView *queryTextScrollView;
	NoodleLineNumberView	*queryTextLineNumberView;

	ConnectionController *connection;
	NSArray *results;
	NSArray *messages;
	int currentResultIndex;  
	BOOL isEdited;
	NSString *fileName;
		
	////syntax highlighting internals
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

@property BOOL isEdited;
@property (copy) NSString *fileName;

- (id) initWithConnection: (ConnectionController*) c;
- (IBAction) resultsMessagesSegmentControlClicked:(id)sender;
- (IBAction) showResults: (id) sender;
- (IBAction) showMessages: (id) sender;
- (void) showResultsCount;

- (IBAction) nextResult: (id) sender;
- (IBAction) previousResult: (id) sender;

- (NSString*) queryString;
- (void) setResults: (NSArray*) r andMessages: (NSArray*) m;

- (BOOL) hasResults;
- (NSArray*) columns;
- (NSArray*) rows;
- (int) rowsCount;
- (NSString*) rowValue: (int) rowIndex: (int) columnIndex;

- (void) reloadResults;
- (void) reloadMessages;
- (void) addColumns;
- (void) addColumn:(ColumnMetadata*) meta;
- (void) removeAllColumns;

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView;
- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex;

- (BOOL) saveQuery;  
- (void) openQuery; 

@end

//syntax highlighting
#define TD_USER_DEFINED_IDENTIFIERS			@"SyntaxColoring:UserIdentifiers"		// Key in user defaults holding user-defined identifiers to colorize.
#define TD_SYNTAX_COLORING_MODE_ATTR		@"UKTextDocumentSyntaxColoringMode"		// Anything we colorize gets this attribute.

@interface QueryController (SyntaxHighlight)

-(void) syntaxColoringInit;
-(IBAction) indentSelection: (id)sender;
-(IBAction) unIndentSelection: (id)sender;
-(IBAction)	recolorCompleteFile: (id)sender;
-(void) recolorRange: (NSRange) range;
-(void)	colorOneLineComment: (NSString*) startCh inString: (NSMutableAttributedString*) s withColor: (NSColor*) col andMode:(NSString*)attr;
-(void)	colorCommentsFrom: (NSString*) startCh to: (NSString*) endCh inString: (NSMutableAttributedString*) s withColor: (NSColor*) col andMode:(NSString*)attr;
-(void)	colorIdentifier: (NSString*) ident inString: (NSMutableAttributedString*) s withColor: (NSColor*) col andMode:(NSString*)attr charset: (NSCharacterSet*)cset;
-(void)	colorStringsFrom: (NSString*) startCh to: (NSString*) endCh inString: (NSMutableAttributedString*) s withColor: (NSColor*) col andMode:(NSString*)attr andEscapeChar: (NSString*)vStringEscapeCharacter;
-(void)	colorTagFrom: (NSString*) startCh to: (NSString*)endCh inString: (NSMutableAttributedString*) s withColor: (NSColor*) col andMode:(NSString*)attr exceptIfMode: (NSString*)ignoreAttr;

-(NSDictionary*)	syntaxDefinitionDictionary; // Defaults to loading from -syntaxDefinitionFilename.
-(NSDictionary*)	defaultTextAttributes;			// Style attributes dictionary for an NSAttributedString.

@end
