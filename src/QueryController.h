#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

#import "TdsConnection.h"
#import "ConnectionController.h"
#import "QueryResult.h"
#import "TableResultDataSource.h"

@class ConnectionController;
@class QueryResult;
                   
#define COMPLETION_DELAY (0.5)

@interface QueryController : NSViewController <NSSplitViewDelegate> {
    
    IBOutlet NSTabView *resultsTabView;
    IBOutlet NSView *resultsContentView;
    IBOutlet NSSegmentedControl *resultsMessagesSegmentedControll;
    IBOutlet NSTextView	*messagesTextView;
    IBOutlet NSView *tableResultsContentView;
    IBOutlet NSSplitView *splitView;
    IBOutlet NSTextView	*textResultsTextView;
    
    IBOutlet WebView *sqlEditor;
    WebScriptObject* queryEditor;
    NSSplitView *tablesSplitView;
    NSScrollView *tablesScrollView;
    NSTableView *firstTableView;
    ConnectionController *connection;
    QueryResult *queryResult;
    int spliterPosition;
    
    BOOL isEdited;
    BOOL isProcessing;
    NSString *status;
    NSString *fileName;
    NSString *name;
    NSString *database;
    int lastResultsTabIndex;
    TdsConnection *executingConnection;
    NSMutableArray *dataSources;
}

@property BOOL isEdited;
@property BOOL isProcessing;
@property (copy) NSString *fileName;
@property (copy) NSString *name;
@property (copy) NSString *database;
@property (copy) NSString *status;

- (void) testCodeMirror;
- (void) setAutocompleteData: (NSMutableDictionary*) dict;

- (id) initWithConnection: (ConnectionController*) c;
- (IBAction) resultsMessagesSegmentControlClicked:(id)sender;
- (void) showResults;
- (void) showTextResults;
- (void) showMessages;

- (NSString*) queryString;
- (NSString*) queryParagraphString;
- (void) setResult: (QueryResult*) r;

- (void) reloadResults;
- (void) reloadMessages;

- (void) splitViewDidResize: (NSNotification *)aNotification;
- (void) createTables;
- (NSTableView*) createTable;
- (void) createTablesPlaceholder;

- (BOOL) saveQuery:(bool)saveAs;
- (BOOL) openFile:(NSString*) fn;
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
- (void) setExecutingConnection: (TdsConnection*) tdsConnection;

- (void) resizeTablesSplitView: (BOOL) andSubviews;
- (void) displayTextResults;

- (void) showErrorMessage: (NSString*) message;

@end