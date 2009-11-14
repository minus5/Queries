#import <Cocoa/Cocoa.h>
#import "ColumnMetadata.h"

#import "TdsConnection.h"
#import "NoodleLineNumberView.h"
#import "NoodleLineNumberMarker.h"
#import "MarkerLineNumberView.h"
#import "ConnectionController.h"
#import "QueryResult.h"
#import <BWToolkitFramework/BWToolkitFramework.h>

@class NoodleLineNumberView;
@class ConnectionController;
@class QueryResult;

#define _WINDEF_
#define TDS50 0
#include <sqlfront.h>	
#include <sybdb.h>

@interface QueryController : NSViewController <NSSplitViewDelegate> {

	IBOutlet NSTabView *resultsTabView;
	IBOutlet NSView *resultsContentView;
	IBOutlet NSSegmentedControl *resultsMessagesSegmentedControll;
	IBOutlet NSTextView	*queryText;
	IBOutlet NSTextView	*messagesTextView;
	IBOutlet NSTableView *resultsTableView;
	IBOutlet NSTableView *tableView;
	IBOutlet NSBox *resultsCountBox;
	IBOutlet NSTextField *resultsCountLabel;	
	IBOutlet NSScrollView *queryTextScrollView;
	NoodleLineNumberView *queryTextLineNumberView;
	IBOutlet BWSplitView *splitView;
	ConnectionController *connection;
	QueryResult *queryResult;             
	
	IBOutlet NSTextView	*textResultsTextView;
	
	BOOL isEdited;
	BOOL isProcessing;
	NSString *fileName;          
	NSString *name;
	NSString *database;                     
	int lastResultsTabIndex;     
	TdsConnection *executingConnection;
		
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
@property BOOL isProcessing;
@property (copy) NSString *fileName;
@property (copy) NSString *name;
@property (copy) NSString *database; 

- (id) initWithConnection: (ConnectionController*) c;
- (IBAction) resultsMessagesSegmentControlClicked:(id)sender;
- (IBAction) showResults: (id) sender;                         
- (IBAction) showTextResults: (id) sender;
- (IBAction) showMessages: (id) sender;
- (void) showResultsCount;
- (IBAction) nextResultsTab: (id) sender;
- (IBAction) previousResultsTab: (id) sender;
- (IBAction) nextResult: (id) sender;
- (IBAction) previousResult: (id) sender;

- (NSString*) queryString;
- (void) setResult: (QueryResult*) r;

- (void) reloadResults;
- (void) reloadMessages;
- (void) addColumns;
- (void) addColumn:(ColumnMetadata*) meta;
- (void) removeAllColumns;

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView;
- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex;

- (BOOL) saveQuery:(bool)saveAs;  
- (void) openFile:(NSString*) fn;
- (IBAction) saveDocument: (id) sender;
- (IBAction) saveDocumentAs: (id) sender;

- (void) setString: (NSString*) s;       

- (IBAction) goToQueryText: (id) sender; 
- (IBAction) goToResults: (id) sender;
- (IBAction) goToMessages: (id) sender;

- (void) updateNextKeyViewRing;                                    

- (void)splitViewDidResizeSubviews:(NSNotification *)aNotification;
- (IBAction) splitResultsAndQueryTextEqualy: sender;
- (IBAction) maximizeResults: sender;
- (IBAction) maximizeQueryText: sender;
- (void) processingStarted;          
- (IBAction) cancelExecutingQuery: (id) sender;

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
