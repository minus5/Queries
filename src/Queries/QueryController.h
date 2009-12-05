#import <Cocoa/Cocoa.h>

#import <BWToolkitFramework/BWToolkitFramework.h>       
#import "NoodleLineNumberView.h"
#import "NoodleLineNumberMarker.h"
#import "MarkerLineNumberView.h"

#import "TdsConnection.h"
#import "ConnectionController.h"
#import "QueryResult.h"
#import "TableResultDataSource.h"

@class NoodleLineNumberView;
@class ConnectionController;
@class QueryResult;
                   
#define COMPLETION_DELAY (0.5)

@interface QueryController : NSViewController <NSSplitViewDelegate> {

	IBOutlet NSTabView *resultsTabView;
	IBOutlet NSView *resultsContentView;
	IBOutlet NSView *queryTextContentView;
	IBOutlet NSSegmentedControl *resultsMessagesSegmentedControll;
	IBOutlet NSTextView	*queryText;
	IBOutlet NSTextView	*messagesTextView; 
	IBOutlet NSScrollView *queryTextScrollView;
	IBOutlet NSView *tableResultsContentView;	
	IBOutlet BWSplitView *splitView;
	IBOutlet NSTextView	*textResultsTextView;
	                                         
	NoodleLineNumberView *queryTextLineNumberView;
	NSSplitView *tablesSplitView;	
	NSScrollView *tablesScrollView;    
	NSTableView *firstTableView;	
	ConnectionController *connection;
	QueryResult *queryResult;               
	int spliterPosition;       
	
	BOOL isEdited;
	BOOL isProcessing;
	NSString *fileName;          
	NSString *name;
	NSString *database;                     
	int lastResultsTabIndex;     
	TdsConnection *executingConnection;
	NSMutableArray *dataSources;
		
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
- (void) showResults;
- (void) showTextResults;
- (void) showMessages;
- (IBAction) nextResultsTab: (id) sender;

- (NSString*) queryString;
- (void) setResult: (QueryResult*) r;

- (void) reloadResults;
- (void) reloadMessages;

- (void) createTables;
- (NSTableView*) createTable;
- (void) createTablesPlaceholder;

- (BOOL) saveQuery:(bool)saveAs;  
- (void) openFile:(NSString*) fn;
- (IBAction) saveDocument: (id) sender;
- (IBAction) saveDocumentAs: (id) sender;

- (void) setString: (NSString*) s;       

- (void) goToQueryText; 
- (void) goToResults;
- (void) goToTextResults;
- (void) goToMessages;


- (IBAction) splitResultsAndQueryTextEqualy: sender;
- (IBAction) maximizeResults: sender;
- (IBAction) maximizeQueryText: sender;
- (IBAction) maximizeQueryResults: sender;
- (IBAction) nextResultsTab: (id) sender;
- (void) ensureResultsAreVisible;
- (void) ensureQueryTextIsVisible;

- (void) processingStarted;          
- (IBAction) cancelExecutingQuery: (id) sender;
-(void) setExecutingConnection: (TdsConnection*) tdsConnection;

- (void) resizeTablesSplitView: (BOOL) andSubviews;

@end

//syntax highlighting
#define TD_USER_DEFINED_IDENTIFIERS			@"SyntaxColoring:UserIdentifiers"		// Key in user defaults holding user-defined identifiers to colorize.
#define TD_SYNTAX_COLORING_MODE_ATTR		@"UKTextDocumentSyntaxColoringMode"		// Anything we colorize gets this attribute.

@interface QueryController (SyntaxHighlight)

-(void) syntaxColoringInit;
-(IBAction) indentSelection: (id)sender;
-(void) recolorRange: (NSRange) range;
-(void)	colorOneLineComment: (NSString*) startCh inString: (NSMutableAttributedString*) s withColor: (NSColor*) col andMode:(NSString*)attr;
-(void)	colorCommentsFrom: (NSString*) startCh to: (NSString*) endCh inString: (NSMutableAttributedString*) s withColor: (NSColor*) col andMode:(NSString*)attr;
-(void)	colorIdentifier: (NSString*) ident inString: (NSMutableAttributedString*) s withColor: (NSColor*) col andMode:(NSString*)attr charset: (NSCharacterSet*)cset;
-(void)	colorStringsFrom: (NSString*) startCh to: (NSString*) endCh inString: (NSMutableAttributedString*) s withColor: (NSColor*) col andMode:(NSString*)attr andEscapeChar: (NSString*)vStringEscapeCharacter;
-(void)	colorTagFrom: (NSString*) startCh to: (NSString*)endCh inString: (NSMutableAttributedString*) s withColor: (NSColor*) col andMode:(NSString*)attr exceptIfMode: (NSString*)ignoreAttr;

-(NSDictionary*)	syntaxDefinitionDictionary; // Defaults to loading from -syntaxDefinitionFilename.
-(NSDictionary*)	defaultTextAttributes;			// Style attributes dictionary for an NSAttributedString.

- (IBAction) unIndentSelection: (id)sender;
- (IBAction)	recolorCompleteFile: (id)sender;
- (void) indentSelectionRange: (NSArray*)r;
- (void) unIndentSelectionRange: (NSArray*)r;

@end
