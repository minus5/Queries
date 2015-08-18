#import "Scintilla/ScintillaView.h"
#import "Scintilla/InfoBar.h"

#import <Cocoa/Cocoa.h>

//#import <BWToolkitFramework/BWToolkitFramework.h>
#import "NoodleLineNumberView.h"
//#import "NoodleLineNumberMarker.h"
//#import "MarkerLineNumberView.h"

#import "TdsConnection.h"
#import "ConnectionController.h"
#import "QueryResult.h"
#import "TableResultDataSource.h"

#import "UKSyntaxColoredTextViewController.h"
#import "Scintilla/ScintillaView.h"

@class NoodleLineNumberView;
@class ConnectionController;
@class QueryResult;

#define COMPLETION_DELAY (0.5)

const char major_keywords[] =
"accessible add all alter analyze and as asc asensitive "
"before between bigint binary blob both by "
"call cascade case change char character check collate column condition connection constraint "
"continue convert create cross current_date current_time current_timestamp current_user cursor "
"database databases day_hour day_microsecond day_minute day_second dec decimal declare default "
"delayed delete desc describe deterministic distinct distinctrow div double drop dual "
"each else elseif enclosed escaped exists exit explain "
"false fetch float float4 float8 for force foreign from fulltext "
"goto grant group "
"having high_priority hour_microsecond hour_minute hour_second "
"if ignore in index infile inner inout insensitive insert int int1 int2 int3 int4 int8 integer "
"interval into is iterate "
"join "
"key keys kill "
"label leading leave left like limit linear lines load localtime localtimestamp lock long "
"longblob longtext loop low_priority "
"master_ssl_verify_server_cert match mediumblob mediumint mediumtext middleint minute_microsecond "
"minute_second mod modifies "
"natural not no_write_to_binlog null numeric "
"on optimize option optionally or order out outer outfile "
"precision primary procedure purge "
"range read reads read_only read_write real references regexp release rename repeat replace "
"require restrict return revoke right rlike "
"schema schemas second_microsecond select sensitive separator set show smallint spatial specific "
"sql sqlexception sqlstate sqlwarning sql_big_result sql_calc_found_rows sql_small_result ssl "
"starting straight_join "
"table terminated then tinyblob tinyint tinytext to trailing trigger true "
"undo union unique unlock unsigned update upgrade usage use using utc_date utc_time utc_timestamp "
"values varbinary varchar varcharacter varying "
"when where while with write "
"xor "
"year_month "
"zerofill";

const char procedure_keywords[] = // Not reserved words but intrinsic part of procedure definitions.
"begin comment end";

const char client_keywords[] = // Definition of keywords only used by clients, not the server itself.
"delimiter";

const char user_keywords[] = // Definition of own keywords, not used by MySQL.
"edit";

@interface QueryController : NSViewController <NSSplitViewDelegate, UKSyntaxColoredTextViewDelegate, ScintillaNotificationProtocol> {
    
    IBOutlet NSTabView *resultsTabView;
    IBOutlet NSView *resultsContentView;
    IBOutlet NSView *queryTextContentView;
    IBOutlet NSSegmentedControl *resultsMessagesSegmentedControll;
    IBOutlet NSTextView	*queryText;
    IBOutlet NSTextView	*messagesTextView;
    IBOutlet NSView *tableResultsContentView;
    IBOutlet NSSplitView *splitView;
    IBOutlet NSTextView	*textResultsTextView;
    
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
    
    ////syntax highlighting internals
    //	IBOutlet NSTextField*			syntaxColoringStatus;									// Status display for things like syntax coloring or background syntax checks.
    //	NSTextView*								syntaxColoringTextView;
    //	BOOL											syntaxColoringAuto;										// Automatically refresh syntax coloring when text is changed?
    //	BOOL											syntaxColoringMaintainIndentation;	  // Keep new lines indented at same depth as their predecessor?
    //	BOOL											syntaxColoringBusy;										// Set while recolorRange is busy, so we don't recursively call recolorRange.
    //	NSRange										syntaxColoringAffectedCharRange;
    //	NSString*									syntaxColoringReplacementString;
    //	NSUndoManager							*syntaxColoringUndoManger;
    NSDictionary							*syntaxColoringDictionary;
    
}

@property BOOL isEdited;
@property BOOL isProcessing;
@property (copy) NSString *fileName;
@property (copy) NSString *name;
@property (copy) NSString *database;
@property (copy) NSString *status;

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


//novi syntax highlighter
-(IBAction)	toggleAutoSyntaxColoring: (id)sender;
-(IBAction)	toggleMaintainIndentation: (id)sender;
-(IBAction) showGoToPanel: (id)sender;
-(IBAction) indentSelection: (id)sender;
-(IBAction) unIndentSelection: (id)sender;
-(IBAction)	toggleCommentForSelection: (id)sender;
-(IBAction)	recolorCompleteFile: (id)sender;

-(NSStringEncoding)	stringEncoding;

-(NSDictionary*)	syntaxDefinitionDictionaryForTextViewController: (id)sender;
- (NSArray *)textView:(NSTextView *)textView completions:(NSArray *) words forPartialWordRange:(NSRange)charRange indexOfSelectedItem:(int *)index;
- (void) textDidChange: (NSNotification *) aNotification;

@end

@implementation QueryController

@synthesize isEdited, isProcessing, fileName, database, name, status;

ScintillaView* mEditor;

#pragma mark ---- properties ----

- (void) processingStarted{
	[self setIsProcessing: YES];          
	
 	[self setStatus: @"Executing query..."];
	[messagesTextView insertText: @"\nExecuting query...\n"];
}

-(BOOL) isEdited
{
    return isEdited;
}
- (void) setIsEdited: (BOOL) value{
	if (value != isEdited){
		isEdited = value;
		[connection isEditedChanged: self];
	}
}

- (NSString*) queryString{

    long startPos = [mEditor message:SCI_GETSELECTIONSTART];
    long endPos = [mEditor message:SCI_GETSELECTIONEND];
    char *query;
    if (startPos == endPos) {
        //nema selekcije, dohvati cijeli text
        long length = [mEditor message:SCI_GETTEXTLENGTH];
        query =  (char *) malloc(sizeof(char) * (length + 1));
        [mEditor message:SCI_GETTEXT wParam:(u_long) (length + 1) lParam:(long) query];
    }
    else {
        query =  (char *) malloc(sizeof(char) * (endPos - startPos + 1));
        [mEditor message:SCI_GETSELTEXT wParam:nil lParam:(long) query];
    }

    NSString *str = [NSString stringWithFormat:@"%s", query];
    return str;
}


- (NSString*) queryParagraphString {

    long curLine = [mEditor message:SCI_LINEFROMPOSITION wParam:(u_long) [mEditor message:SCI_GETCURRENTPOS]];
    long startLine = curLine;
    long endLine = curLine;
    //nađi početak paragrafa
    while((([mEditor message:SCI_GETLINEENDPOSITION wParam:(u_long) curLine] - [mEditor message:SCI_POSITIONFROMLINE wParam:(u_long)curLine]) != 0) && curLine != 0) {
        curLine --;
    }
    startLine = curLine;
    curLine = endLine;

    //nađi kraj paragrafa
    while ([mEditor message:SCI_GETLINEENDPOSITION wParam:(u_long) curLine] - [mEditor message:SCI_POSITIONFROMLINE wParam:(u_long) curLine] != 0 && curLine != [mEditor message:SCI_GETLINECOUNT]) {
        curLine++;
    }
    if(curLine == [mEditor message:SCI_GETLINECOUNT]) curLine--;
    endLine = curLine;

    long startPos = [mEditor message:SCI_POSITIONFROMLINE wParam:(u_long) startLine];
    long endPos = [mEditor message:SCI_GETLINEENDPOSITION wParam:(u_long) endLine];
    [mEditor message:SCI_SETSELECTIONSTART wParam:(u_long) startPos];
    [mEditor message:SCI_SETSELECTIONEND wParam:(u_long) endPos];

    char *query =  (char *) malloc(sizeof(char) * (endPos - startPos + 1));

    [mEditor message:SCI_GETSELTEXT wParam:nil lParam:(long) query];

    NSString *str = [NSString stringWithFormat:@"%s", query];
    NSLog(str);
    return str;
}

- (void) setString: (NSString*) s{
    [mEditor message:SCI_SETTEXT wParam:nil lParam:(long) [s UTF8String]];
	[self setIsEdited: NO];
}


#pragma mark ---- init ----

- (id) initWithConnection: (ConnectionController*) c{
	if (self = [super init]){
		connection = c;
		status = @"";	
        dataSources = [[NSMutableArray alloc] init];   
	}             
	return self;
}

- (void) dealloc{         
	NSLog(@"[%@ dealloc]", [self class]);     
	[[NSNotificationCenter defaultCenter] removeObserver:self];   	
	[queryResult release];                       
	[dataSources release];
	
	[super dealloc];
}

- (NSString*) nibName{
	return @"QueryView";
}    

- (void) setNoWrapToTextView: (NSTextView*) tv{ 
	[[tv textContainer] setContainerSize:NSMakeSize(FLT_MAX, FLT_MAX)];
	[[tv textContainer] setWidthTracksTextView:NO];
	[tv setHorizontallyResizable:YES];
	[tv setMaxSize:NSMakeSize(FLT_MAX, FLT_MAX)];                                             
}

- (void) awakeFromNib{
//    [queryText setHidden:YES];
    // Manually set up the scintilla editor. Create an instance and dock it to our edit host.
    // Leave some free space around the new view to avoid overlapping with the box borders.
    NSRect newFrame = queryTextContentView.frame;
//    newFrame.size.width -= 2 * newFrame.origin.x;
//    newFrame.size.height -= 3 * newFrame.origin.y;
    mEditor = [[[ScintillaView alloc] initWithFrame: newFrame] autorelease];
    
    [queryTextContentView addSubview: mEditor];
    [mEditor setAutoresizesSubviews: YES];
    [mEditor setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
	[self setupEditor];
    
	[self setIsEdited: NO];
   
    //proportional font to all text views
	[queryText setFont:[NSFont userFixedPitchFontOfSize:[NSFont smallSystemFontSize]]];                                     
 	[messagesTextView setFont:[NSFont userFixedPitchFontOfSize:[NSFont smallSystemFontSize]]];
	[textResultsTextView setFont:[NSFont userFixedPitchFontOfSize:[NSFont smallSystemFontSize]]];
	
	[self setNoWrapToTextView:messagesTextView];
	[self setNoWrapToTextView:queryText];
	[self setNoWrapToTextView:textResultsTextView];
	
	[self splitViewDidResize: nil];  
    spliterPosition = 0;
	lastResultsTabIndex	= 0;
	[self maximizeQueryText: nil];
	                                                               
	//key ring
	[messagesTextView setNextKeyView: [connection outlineView]];
	[textResultsTextView setNextKeyView: [connection outlineView]];	
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(splitViewDidResize:)
																							 name: NSSplitViewDidResizeSubviewsNotification
																						 object: splitView];
	
}      

/**
 * Initialize scintilla editor (styles, colors, markers, folding etc.].
 */
- (void) setupEditor
{
    // Lexer type is SQL.
    [mEditor setGeneralProperty: SCI_SETLEXER parameter:SCLEX_SQL value:0];
    
    // Number of styles we use with this lexer.
    [mEditor setGeneralProperty: SCI_SETSTYLEBITS value: [mEditor getGeneralProperty: SCI_GETSTYLEBITSNEEDED]];

    // Keywords to highlight. Indices are:
    // 0 - Major keywords (reserved keywords)
    // 1 - Normal keywords (everything not reserved but integral part of the language)
    // 2 - Database objects
    // 3 - Function keywords
    // 4 - System variable keywords
    // 5 - Procedure keywords (keywords used in procedures like "begin" and "end")
    // 6..8 - User keywords 1..3
    [mEditor setReferenceProperty: SCI_SETKEYWORDS parameter: 0 value: major_keywords];
    [mEditor setReferenceProperty: SCI_SETKEYWORDS parameter: 5 value: procedure_keywords];
    [mEditor setReferenceProperty: SCI_SETKEYWORDS parameter: 6 value: client_keywords];
    [mEditor setReferenceProperty: SCI_SETKEYWORDS parameter: 7 value: user_keywords];
    
    // Colors and styles for various syntactic elements. First the default style.
    [mEditor setStringProperty: SCI_STYLESETFONT parameter: STYLE_DEFAULT value: @"Helvetica"];
    // [mEditor setStringProperty: SCI_STYLESETFONT parameter: STYLE_DEFAULT value: @"Monospac821 BT"]; // Very pleasing programmer's font.
    [mEditor setGeneralProperty: SCI_STYLESETSIZE parameter: STYLE_DEFAULT value: 14];
    [mEditor setColorProperty: SCI_STYLESETFORE parameter: STYLE_DEFAULT value: [NSColor blackColor]];
    
    [mEditor setGeneralProperty: SCI_STYLECLEARALL parameter: 0 value: 0];
    
    [mEditor setColorProperty: SCI_STYLESETFORE parameter: SCE_MYSQL_DEFAULT value: [NSColor blackColor]];
    [mEditor setColorProperty: SCI_STYLESETFORE parameter: SCE_MYSQL_COMMENT fromHTML: @"#097BF7"];
    [mEditor setColorProperty: SCI_STYLESETFORE parameter: SCE_MYSQL_COMMENTLINE fromHTML: @"#097BF7"];
    [mEditor setColorProperty: SCI_STYLESETFORE parameter: SCE_MYSQL_HIDDENCOMMAND fromHTML: @"#097BF7"];
    [mEditor setColorProperty: SCI_STYLESETBACK parameter: SCE_MYSQL_HIDDENCOMMAND fromHTML: @"#F0F0F0"];
    
    [mEditor setColorProperty: SCI_STYLESETFORE parameter: SCE_MYSQL_VARIABLE fromHTML: @"378EA5"];
    [mEditor setColorProperty: SCI_STYLESETFORE parameter: SCE_MYSQL_SYSTEMVARIABLE fromHTML: @"378EA5"];
    [mEditor setColorProperty: SCI_STYLESETFORE parameter: SCE_MYSQL_KNOWNSYSTEMVARIABLE fromHTML: @"#3A37A5"];
    
    [mEditor setColorProperty: SCI_STYLESETFORE parameter: SCE_MYSQL_NUMBER fromHTML: @"#7F7F00"];
    [mEditor setColorProperty: SCI_STYLESETFORE parameter: SCE_MYSQL_SQSTRING fromHTML: @"#FFAA3E"];
    
    // Note: if we were using ANSI quotes we would set the DQSTRING to the same color as the
    //       the back tick string.
    [mEditor setColorProperty: SCI_STYLESETFORE parameter: SCE_MYSQL_DQSTRING fromHTML: @"#274A6D"];
    
    // Keyword highlighting.
    [mEditor setColorProperty: SCI_STYLESETFORE parameter: SCE_MYSQL_MAJORKEYWORD fromHTML: @"#007F00"];
    [mEditor setGeneralProperty: SCI_STYLESETBOLD parameter: SCE_MYSQL_MAJORKEYWORD value: 1];
    [mEditor setColorProperty: SCI_STYLESETFORE parameter: SCE_MYSQL_KEYWORD fromHTML: @"#007F00"];
    [mEditor setGeneralProperty: SCI_STYLESETBOLD parameter: SCE_MYSQL_KEYWORD value: 1];
    [mEditor setColorProperty: SCI_STYLESETFORE parameter: SCE_MYSQL_PROCEDUREKEYWORD fromHTML: @"#56007F"];
    [mEditor setGeneralProperty: SCI_STYLESETBOLD parameter: SCE_MYSQL_PROCEDUREKEYWORD value: 1];
    [mEditor setColorProperty: SCI_STYLESETFORE parameter: SCE_MYSQL_USER1 fromHTML: @"#808080"];
    [mEditor setColorProperty: SCI_STYLESETFORE parameter: SCE_MYSQL_USER2 fromHTML: @"#808080"];
    [mEditor setColorProperty: SCI_STYLESETBACK parameter: SCE_MYSQL_USER2 fromHTML: @"#F0E0E0"];
    
    // The following 3 styles have no impact as we did not set a keyword list for any of them.
    [mEditor setColorProperty: SCI_STYLESETFORE parameter: SCE_MYSQL_DATABASEOBJECT value: [NSColor redColor]];
    [mEditor setColorProperty: SCI_STYLESETFORE parameter: SCE_MYSQL_FUNCTION value: [NSColor redColor]];
    
    [mEditor setColorProperty: SCI_STYLESETFORE parameter: SCE_MYSQL_IDENTIFIER value: [NSColor blackColor]];
    [mEditor setColorProperty: SCI_STYLESETFORE parameter: SCE_MYSQL_QUOTEDIDENTIFIER fromHTML: @"#274A6D"];
    [mEditor setGeneralProperty: SCI_STYLESETBOLD parameter: SCE_SQL_OPERATOR value: 1];
    
    // Line number style.
    [mEditor setColorProperty: SCI_STYLESETFORE parameter: STYLE_LINENUMBER fromHTML: @"#808080"];
    [mEditor setColorProperty: SCI_STYLESETBACK parameter: STYLE_LINENUMBER fromHTML: @"#F0F0F0"];
    
    [mEditor setGeneralProperty: SCI_SETMARGINTYPEN parameter: 0 value: SC_MARGIN_NUMBER];
    [mEditor setGeneralProperty: SCI_SETMARGINWIDTHN parameter: 0 value: 15];
    
    // Markers.
    [mEditor setGeneralProperty: SCI_SETMARGINWIDTHN parameter: 1 value: 0];
    
    // Some special lexer properties.
    [mEditor setLexerProperty: @"fold" value: @"1"];
    [mEditor setLexerProperty: @"fold.compact" value: @"0"];
    [mEditor setLexerProperty: @"fold.comment" value: @"1"];
    [mEditor setLexerProperty: @"fold.preprocessor" value: @"1"];
    
    // Folder setup.
    [mEditor setGeneralProperty: SCI_SETMARGINWIDTHN parameter: 2 value: 10];
    [mEditor setGeneralProperty: SCI_SETMARGINMASKN parameter: 2 value: SC_MASK_FOLDERS];
    [mEditor setGeneralProperty: SCI_SETMARGINSENSITIVEN parameter: 2 value: 1];
    [mEditor setGeneralProperty: SCI_MARKERDEFINE parameter: SC_MARKNUM_FOLDEROPEN value: SC_MARK_BOXMINUS];
    [mEditor setGeneralProperty: SCI_MARKERDEFINE parameter: SC_MARKNUM_FOLDER value: SC_MARK_BOXPLUS];
    [mEditor setGeneralProperty: SCI_MARKERDEFINE parameter: SC_MARKNUM_FOLDERSUB value: SC_MARK_VLINE];
    [mEditor setGeneralProperty: SCI_MARKERDEFINE parameter: SC_MARKNUM_FOLDERTAIL value: SC_MARK_LCORNER];
    [mEditor setGeneralProperty: SCI_MARKERDEFINE parameter: SC_MARKNUM_FOLDEREND value: SC_MARK_BOXPLUSCONNECTED];
    [mEditor setGeneralProperty: SCI_MARKERDEFINE parameter: SC_MARKNUM_FOLDEROPENMID value: SC_MARK_BOXMINUSCONNECTED];
    [mEditor setGeneralProperty
     : SCI_MARKERDEFINE parameter: SC_MARKNUM_FOLDERMIDTAIL value: SC_MARK_TCORNER];
    for (int n= 25; n < 32; ++n) // Markers 25..31 are reserved for folding.
    {
        [mEditor setColorProperty: SCI_MARKERSETFORE parameter: n value: [NSColor whiteColor]];
        [mEditor setColorProperty: SCI_MARKERSETBACK parameter: n value: [NSColor blackColor]];
    }
    
    // Init markers & indicators for highlighting of syntax errors.
    [mEditor setColorProperty: SCI_INDICSETFORE parameter: 0 value: [NSColor redColor]];
    [mEditor setGeneralProperty: SCI_INDICSETUNDER parameter: 0 value: 1];
    [mEditor setGeneralProperty: SCI_INDICSETSTYLE parameter: 0 value: INDIC_SQUIGGLE];
    
    [mEditor setColorProperty: SCI_MARKERSETBACK parameter: 0 fromHTML: @"#B1151C"];
    
    [mEditor setColorProperty: SCI_SETSELBACK parameter: 1 value: [NSColor selectedTextBackgroundColor]];
    
    // Uncomment if you wanna see auto wrapping in action.
    //[mEditor setGeneralProperty: SCI_SETWRAPMODE parameter: SC_WRAP_WORD value: 0];

    // Line endings
//    [mEditor message:SCI_SETVIEWEOL wParam:1];
//    [mEditor message:SCI_SETLINEENDTYPESALLOWED wParam:SC_LINE_END_TYPE_UNICODE];


    InfoBar* infoBar = [[[InfoBar alloc] initWithFrame: NSMakeRect(0, 0, 400, 0)] autorelease];
    [infoBar setDisplay: IBShowAll];
    [mEditor setInfoBar: infoBar top: NO];
    [mEditor setStatusText: @"Operation complete"];
    
    [mEditor  setDelegate:self];
}

#pragma mark ---- Scintilla ----
- (void)notification: (Scintilla::SCNotification*)notification{
    switch (notification->nmhdr.code) {
        case SCN_CHARADDED:
            
            break;
        case SCN_MODIFIED:
            [self showAutocompletion: notification->position+1];
            break;
        default:
            break;
    }
}

- (void) showAutocompletion:(int)length
{
    const char *words = "select top";
    [mEditor setGeneralProperty: SCI_AUTOCSETIGNORECASE parameter: 1 value:0];
    [mEditor setGeneralProperty: SCI_AUTOCSHOW parameter: length value:(sptr_t)words];
}

#pragma mark ---- positioning ----

- (void) splitViewDidResize: (NSNotification *)aNotification{	
	NSRect frame = [resultsTabView frame];
	frame.size.height = [resultsContentView frame].size.height - 35;	
	frame.origin.x = 0;
	frame.origin.y = 0;
	if (frame.size.height >= 0){
		[resultsTabView setFrame: frame];				
	}  
	[self resizeTablesSplitView: NO];
}   

- (CGFloat)splitView:(NSSplitView *)sender constrainMinCoordinate:(CGFloat)proposedMin ofSubviewAt:(NSInteger)dividerIndex{
  NSView *subview = [[sender subviews] objectAtIndex: dividerIndex];
	if (sender == tablesSplitView){
		return [subview frame].origin.y + 32.5;
	}        
	else
	{
		return proposedMin;
	}
} 

- (CGFloat)splitView:(NSSplitView *)sender constrainMaxCoordinate:(CGFloat)proposedMax ofSubviewAt:(NSInteger)dividerIndex{  
	if (sender == tablesSplitView){
		NSView *subview = [[sender subviews] objectAtIndex: dividerIndex + 1];  
		return [subview frame].origin.y + [subview frame].size.height - 32.5 - 9;
	}        
	else
	{
		return proposedMax;
	}
} 
  
#pragma mark ---- tab navigation ----

- (IBAction)resultsMessagesSegmentControlClicked:(id)sender
{
	[resultsTabView selectTabViewItemAtIndex: [sender selectedSegment]];
} 

- (void) makeResultsFirstResponder{
	int selectedIndex = [resultsTabView indexOfTabViewItem: [resultsTabView selectedTabViewItem]];	
	switch(selectedIndex){
		case 0:                      
			if (firstTableView)
				[[connection window] makeFirstResponder: firstTableView];
			break;
		case 1:
			[[connection window] makeFirstResponder: textResultsTextView];
			break;
		case 2: 
			[[connection window] makeFirstResponder: messagesTextView];
			break;
	}
}

- (void) tabView:(NSTabView *)tabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem{
	int selectedIndex = [resultsTabView indexOfTabViewItem: tabViewItem];	
	[resultsMessagesSegmentedControll setSelectedSegment: selectedIndex];  
	switch(selectedIndex){
		case 0:                      
			[self resizeTablesSplitView: NO];
			if (firstTableView)
				[queryText setNextKeyView: firstTableView];
			break;
		case 1:                                                      
			[self displayTextResults];	
			[queryText setNextKeyView: textResultsTextView];
			break;
		case 2: 
			[queryText setNextKeyView: messagesTextView];
			break;
	} 
	if (selectedIndex != 2)
		lastResultsTabIndex = selectedIndex;
}

- (void) displayTextResults{
	int selectedIndex = [resultsTabView indexOfTabViewItem: [resultsTabView selectedTabViewItem]];
	if (selectedIndex == 1){
		if ([[textResultsTextView string] length] == 0){
			[textResultsTextView setString: [queryResult resultsInText]];
			[textResultsTextView setSelectedRange: NSMakeRange(0, 0)];
		}                       
	}
}  
                             
- (void) showResults{
	[resultsTabView	selectTabViewItemAtIndex: 0];
}

- (void) showTextResults{
	[resultsTabView	selectTabViewItemAtIndex: 1];
}

- (void) showMessages{
	[resultsTabView	selectTabViewItemAtIndex: 2];
}                                                                               

- (bool) lastTabSelected{
	return [resultsTabView indexOfTabViewItem: [resultsTabView selectedTabViewItem]] == [[resultsTabView tabViewItems] count] - 1;
}

- (IBAction) nextResultsTab: (id) sender{ 	
	[self ensureResultsAreVisible]; 	
	if (!([[connection window] firstResponder] == queryText)){
		if ([self lastTabSelected]){
			[resultsTabView selectFirstTabViewItem: sender];
		}else{
			[resultsTabView selectNextTabViewItem: sender];		
		}    	                                           
	}
	[self makeResultsFirstResponder];
}

#pragma mark ---- navigation goto control ----     

- (void) goToQueryText{ 
	[self ensureQueryTextIsVisible];	
	[[connection window] makeFirstResponder: queryText];
}
                                        
- (void) goToResults{         
	[self ensureResultsAreVisible];            
	[self showResults];              
	[self makeResultsFirstResponder];
}

- (void) goToTextResults{
	[self ensureResultsAreVisible];
	[self showTextResults];
	[self makeResultsFirstResponder];
}

- (void) goToMessages{       
	[self ensureResultsAreVisible];              
	[self showMessages];
	[self makeResultsFirstResponder];
}
 
- (void) ensureResultsAreVisible{    		
	if ([resultsContentView frame].size.height < 20){
		[self splitResultsAndQueryTextEqualy: nil];
	}
}  

- (void) ensureQueryTextIsVisible{
	if ([queryTextContentView frame].size.height < 5){
		[self splitResultsAndQueryTextEqualy: nil];
	}
}
      
#pragma mark ---- navigation maximize view ----       

- (IBAction) maximizeQueryResults: sender{
	switch(spliterPosition){
		case 0:
			[self maximizeResults: sender];
			break;
		case 1:
			[self splitResultsAndQueryTextEqualy: sender];
			break;
		case 2:
			[self maximizeQueryText: sender];
			break;
	}
}

- (IBAction) splitResultsAndQueryTextEqualy: sender{
	[splitView setPosition: ([splitView frame].size.height * 0.3) ofDividerAtIndex:0];
	spliterPosition = 2;
}

- (IBAction) maximizeResults: sender{
	[splitView setPosition: 0 ofDividerAtIndex:0];
	spliterPosition = 1;
	[self makeResultsFirstResponder];
}

- (IBAction) maximizeQueryText: sender{
    [splitView setPosition: ([splitView frame].size.height) ofDividerAtIndex:0];
	spliterPosition = 0;             
	[[connection window] makeFirstResponder: queryText];
}
                                     
#pragma mark ---- show results ----

- (void) setResult: (QueryResult*) r{     
	executingConnection = nil;
	if (!r) return;
	
	[queryResult release];
	queryResult = r;
	[queryResult retain]; 
	                   
	if ([queryResult database])
		[self setDatabase: [queryResult database]];		
		
	[self reloadResults];
	[self reloadMessages];
	[textResultsTextView setString: @""];
	
	if ([queryResult hasResults] && ![queryResult hasErrors]){           	  
		[resultsTabView selectTabViewItemAtIndex: lastResultsTabIndex];	 
		[self displayTextResults];        
	}else {
		[self showMessages];
	}
    [self ensureResultsAreVisible];
		
	[self setIsProcessing: NO];
	[[ConnectionsManager sharedInstance] cleanup];
	[self setStatus: [queryResult status]];
}                                       

-(void) reloadMessages{
	[messagesTextView setString:@""];
	for(id message in [queryResult messages]){			
		[messagesTextView insertText: message];	
	}   
	[messagesTextView insertText: @"\n"];			
}

-(void) showErrorMessage: (NSString*) message{
	[messagesTextView insertText: message];		
    [self showMessages];
	[self setStatus: @"Error"];
}
        
- (void) reloadResults{
	[self createTablesPlaceholder];
	[self createTables]; 
	[self resizeTablesSplitView: YES];
}

- (void) createTables{  
	firstTableView = nil;	
	//clear existing
	int count = [[tablesSplitView subviews] count];
	for(int i = count-1; i>=0; i--){
		NSView *subview = [[tablesSplitView subviews] objectAtIndex: i];		
		[subview removeFromSuperview];
		[dataSources removeAllObjects];
	}               
	//add new
	NSTableView *prevoiusTableView = nil;
	for(int i=0; i<[queryResult resultsCount]; i++){
		NSTableView *newTableView = [self createTable];
		TableResultDatasource *dataSource = [[TableResultDatasource alloc] initWithTableView: newTableView andColumns: [queryResult columnsAtIndex:i] andRows: [queryResult resultAtIndex:i]];
		[dataSources addObject: dataSource];		
		[dataSource release];
		
		[newTableView setDataSource: dataSource];
		[dataSource bind];		                
		[queryResult nextResult];                               
      
    //keyRingCorection
		if (prevoiusTableView != nil){
			[prevoiusTableView setNextKeyView: newTableView];
		}
		[newTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
		[newTableView setNextKeyView: [connection outlineView]];
		prevoiusTableView = newTableView;    		                                               
		if (i==0){      
			firstTableView = newTableView;  
			[queryText setNextKeyView: newTableView];
		}
	}
}

- (NSTableView*) createTable{
  //prebaci split i table na autorelease pool
  //a i data source od tablice

	//todo - koju velicinu frame-a postaviti ovdje
	NSScrollView *newScrollView = [[NSScrollView alloc] initWithFrame: [tablesSplitView frame]];
	[newScrollView setHasVerticalScroller:YES];
	[newScrollView setHasHorizontalScroller:YES];
	[newScrollView setAutohidesScrollers: YES];		
	[newScrollView setAutoresizesSubviews:YES];
	[newScrollView setAutoresizingMask: NSViewHeightSizable | NSViewWidthSizable];
	
	NSTableView *newTableView = [[NSTableView alloc] init];
	[newTableView setAutoresizingMask: NSViewHeightSizable | NSViewWidthSizable];
	[newTableView setUsesAlternatingRowBackgroundColors: YES];
	[newTableView setGridStyleMask:NSTableViewSolidVerticalGridLineMask];
	[newTableView setRowHeight: 14];
	[newTableView setFocusRingType: NSFocusRingTypeNone];  
	[newTableView setColumnAutoresizingStyle: NSTableViewNoColumnAutoresizing];
	[newTableView setAllowsMultipleSelection: YES];

	[newScrollView setDocumentView:newTableView];
	[tablesSplitView addSubview:newScrollView];		
	[newTableView release];
	[newScrollView release];
	
	return newTableView;
}                    

- (void) createTablesPlaceholder{    
  if (tablesScrollView)
		return;
	
	tablesScrollView = [[NSScrollView alloc] initWithFrame: [tableResultsContentView frame]];
	[tablesScrollView setHasVerticalScroller: NO];
	[tablesScrollView setHasHorizontalScroller: NO];
	[tablesScrollView setAutohidesScrollers: NO];		
	[tablesScrollView setAutoresizesSubviews: YES];
	[tablesScrollView setAutoresizingMask: NSViewHeightSizable | NSViewWidthSizable];
	
	tablesSplitView = [[NSSplitView alloc] initWithFrame: [tableResultsContentView frame]];
	[tablesSplitView setAutoresizesSubviews: NO];	
	[tablesScrollView setDocumentView: tablesSplitView];
	[tableResultsContentView addSubview: tablesScrollView];
	[tablesSplitView release];
	[tablesScrollView release];
	[tablesSplitView setDelegate: self];
}      

- (float) biggerOf: (float) a andOf: (float) b
{
	if ( a > b )
		return a;
	else 
		return b;	
}   

- (void)scrollScrollViewToTop:(NSScrollView*) scrollView ;
{
	NSPoint newScrollOrigin;	
	if ([[scrollView documentView] isFlipped]) {
		newScrollOrigin=NSMakePoint(0.0,0.0);
	} else {
		newScrollOrigin=NSMakePoint(0.0,NSMaxY([[scrollView documentView] frame])-NSHeight([[scrollView contentView] bounds]));
	}	
	[[scrollView documentView] scrollPoint:newScrollOrigin];	
}

- (float) minHeightForTableAtIndex:(int)index{
	int rows = [[queryResult resultAtIndex: index] count];	
	return 32.5 + (rows > 9 ? 9 : rows) * 17.5;	
}

- (void) resizeTablesSplitView: (BOOL) andSubviews{	 	  
	int count = [[tablesSplitView subviews] count];
	float splitersHeight = (count - 1) * 9;            
	
	float minHeightOfAllTables = 0;
	for(int i = [[tablesSplitView subviews] count]-1; i>=0; i--){
		minHeightOfAllTables += [self minHeightForTableAtIndex: i];
	}
	
	float splitViewHeight = [self biggerOf: (minHeightOfAllTables + splitersHeight) andOf: [tablesScrollView frame].size.height];
	
	//resize split view
	[tablesScrollView setHasVerticalScroller: splitViewHeight > [tablesScrollView contentSize].height];				
	NSRect splitViewRect;
	splitViewRect.size.width = [tablesScrollView contentSize].width;
	splitViewRect.size.height = splitViewHeight;
	splitViewRect.origin.x = 0;
	splitViewRect.origin.y = [tablesScrollView contentSize].height - splitViewRect.size.height;	
	[tablesSplitView setFrame: splitViewRect];
	
	if (andSubviews){
		float allTablesHeight = splitViewHeight - splitersHeight; 
		for(int i=0; i < count; i++){
			float tableHeight = ([self minHeightForTableAtIndex: i] / minHeightOfAllTables) * allTablesHeight;
			NSView *subview = [[tablesSplitView subviews] objectAtIndex: i];
			NSRect frame;
			frame.origin.x = 0;
			frame.size.width = [tablesSplitView frame].size.width;
			frame.size.height = tableHeight;  
			[subview setFrame:frame];
		}		
	}
	
	[self scrollScrollViewToTop: tablesScrollView];	
}
                             
#pragma mark ---- save open ----

- (void) textDidChange: (NSNotification *) aNotification{
	[self setIsEdited: TRUE];
}

- (IBAction) saveDocument: (id) sender {
	[self saveQuery: NO];
}                          

- (IBAction) saveDocumentAs: (id) sender {
	[self saveQuery: YES];
}                          

- (BOOL) saveQuery:(bool) saveAs{		
	if (!fileName || saveAs){
		NSSavePanel *panel = [NSSavePanel savePanel];  
		[panel setExtensionHidden: NO];
		if (fileName)
			[panel setNameFieldStringValue: [fileName lastPathComponent]];
		else
		  if (name)	  	                                                
				[panel setNameFieldStringValue: name];
    NSArray* types = [NSArray arrayWithObject:(id) @"sql"];
		[panel setAllowedFileTypes: types];
		if (![panel runModal] == NSOKButton) {
			return NO;
		}                                                                      
		[self setFileName: [panel URL].path];  
		[self setName: [[fileName lastPathComponent] stringByDeletingPathExtension]];		
	}	
	[[queryText string] writeToFile: fileName atomically:YES encoding:NSUTF8StringEncoding error:NULL];
  [[NSDocumentController sharedDocumentController] noteNewRecentDocumentURL:[NSURL fileURLWithPath:fileName]];		
	[self setIsEdited: NO];            	
	return YES;
}

- (BOOL) openFile: (NSString*) fn{
	[self setFileName: fn];                       
	[self setName: [[fileName lastPathComponent] stringByDeletingPathExtension]];
	NSString *fileContents = [NSString stringWithContentsOfFile:fileName encoding:NSUTF8StringEncoding error:NULL];
	[queryText setString: fileContents];
	[queryText setSelectedRange: NSMakeRange(0, 0)];
	[self setIsEdited: NO];
	return YES;
}

#pragma mark ---- execute ----

- (IBAction) cancelExecutingQuery: (id) sender {
	if (executingConnection){
		NSLog(@"canceling current query execution");
		[executingConnection setCancelQuery];
		[self setIsProcessing: NO];
		[messagesTextView insertText: @"Query canceled\n"];
		[self setStatus: @"Query canceled"];
	}
}

-(void) setExecutingConnection: (TdsConnection*) tdsConnection{
	executingConnection = tdsConnection;
}                                                             

- (void) keyDown:(NSEvent *)theEvent{
	NSLog(@"query received keyDown event");	
}
      

#pragma mark ---- auto compleletioin ---- 

- (NSArray *)textView:(NSTextView *)textView completions:(NSArray *) words forPartialWordRange:(NSRange)charRange indexOfSelectedItem:(int *)index {
	return [connection objectNamesForAutocompletionInDatabase: database withSearchString: [[queryText string] substringWithRange:charRange]];					                       
}

#pragma mark syntax highlighting delegates

-(void)	textViewControllerWillStartSyntaxRecoloring: (UKSyntaxColoredTextViewController*)sender		// Show your progress indicator.
{
//	[progress startAnimation: self];
//	[progress display];
}


-(void)	textViewControllerDidFinishSyntaxRecoloring: (UKSyntaxColoredTextViewController*)sender		// Hide your progress indicator.
{
//	[progress stopAnimation: self];
//	[progress display];
}


-(void)	selectionInTextViewController: (UKSyntaxColoredTextViewController*)sender						// Update any selection status display.
							changedToStartCharacter: (NSUInteger)startCharInLine endCharacter: (NSUInteger)endCharInLine
															 inLine: (NSUInteger)lineInDoc startCharacterInDocument: (NSUInteger)startCharInDoc
							 endCharacterInDocument: (NSUInteger)endCharInDoc;
{
//	NSString*	statusMsg = nil;
//	NSImage*	selKindImg = nil;
//	
//	if( startCharInDoc < endCharInDoc )
//	{
//		statusMsg = NSLocalizedString(@"character %lu to %lu of line %lu (%lu to %lu in document).",@"selection description in syntax colored text documents.");
//		statusMsg = [NSString stringWithFormat: statusMsg, startCharInLine +1, endCharInLine +1, lineInDoc +1, startCharInDoc +1, endCharInDoc +1];
//		selKindImg = [NSImage imageNamed: @"SelectionRange"];
//	}
//	else
//	{
//		statusMsg = NSLocalizedString(@"character %lu of line %lu (%lu in document).",@"insertion mark description in syntax colored text documents.");
//		statusMsg = [NSString stringWithFormat: statusMsg, startCharInLine +1, lineInDoc +1, startCharInDoc +1];
//		selKindImg = [NSImage imageNamed: @"InsertionMark"];
//	}
//	
//	[selectionKindImage setImage: selKindImg];
//	[status setStringValue: statusMsg];
//	[status display];
}

// -----------------------------------------------------------------------------
//	stringEncoding
//		The encoding as which we will read/write the file data from/to disk.
// -----------------------------------------------------------------------------

-(NSStringEncoding)	stringEncoding
{
	return NSMacOSRomanStringEncoding;
}


/* -----------------------------------------------------------------------------
 dataRepresentationOfType:
 Save raw text to a file as MacRoman text.
 -------------------------------------------------------------------------- */

-(NSData*)	dataRepresentationOfType: (NSString*)aType
{
	//return [[textView string] dataUsingEncoding: [self stringEncoding] allowLossyConversion: YES];
	return nil;
}


/* -----------------------------------------------------------------------------
 loadDataRepresentation:ofType:
 Load plain MacRoman text from a text file.
 -------------------------------------------------------------------------- */

-(BOOL)	loadDataRepresentation: (NSData*)data ofType: (NSString*)aType
{
//	// sourceCode is a member variable:
//	if( sourceCode )
//	{
//		[sourceCode release];   // Release any old text.
//		sourceCode = nil;
//	}
//	sourceCode = [[NSString alloc] initWithData:data encoding: [self stringEncoding]]; // Load the new text.
//	
//	/* Try to load it into textView and syntax colorize it: */
//	[textView setString: sourceCode];
//	
//	// Try to get selection info if possible:
//	NSAppleEventDescriptor*  evt = [[NSAppleEventManager sharedAppleEventManager] currentAppleEvent];
//	if( evt )
//	{
//		NSAppleEventDescriptor*  param = [evt paramDescriptorForKeyword: keyAEPosition];
//		if( param )		// This is always false when Xcode calls us???
//		{
//			NSData*					data = [param data];
//			struct SelectionRange   range;
//			
//			memmove( &range, [data bytes], sizeof(range) );
//			
//			if( range.lineNum >= 0 )
//				[syntaxColoringController goToLine: range.lineNum +1];
//			else
//				[syntaxColoringController goToRangeFrom: range.startRange toChar: range.endRange];
//		}
//	}
	
	return YES;
}


/* -----------------------------------------------------------------------------
 toggleAutoSyntaxColoring:
 Action for menu item that toggles automatic syntax coloring on and off.
 -------------------------------------------------------------------------- */

-(IBAction)	toggleAutoSyntaxColoring: (id)sender
{
    NSLog(@"%s", sel_getName(_cmd));
}


/* -----------------------------------------------------------------------------
 toggleMaintainIndentation:
 Action for menu item that toggles indentation maintaining on and off.
 -------------------------------------------------------------------------- */

-(IBAction)	toggleMaintainIndentation: (id)sender
{
    NSLog(@"%s", sel_getName(_cmd));
}


/* -----------------------------------------------------------------------------
 showGoToPanel:
 Action for menu item that shows the "Go to line" panel.
 -------------------------------------------------------------------------- */

-(IBAction) showGoToPanel: (id)sender
{
	//[gotoPanel showGoToSheet: [self windowForSheet]];
}


// -----------------------------------------------------------------------------
//	indentSelection:
//		Action method for "indent selection" menu item.
// -----------------------------------------------------------------------------

-(IBAction) indentSelection: (id)sender
{
    NSLog(@"%s", sel_getName(_cmd));
}


// -----------------------------------------------------------------------------
//	unindentSelection:
//		Action method for "un-indent selection" menu item.
// -----------------------------------------------------------------------------

-(IBAction) unIndentSelection: (id)sender
{
    NSLog(@"%s", sel_getName(_cmd));
}


/* -----------------------------------------------------------------------------
 toggleCommentForSelection:
 Add a comment to the start of this line/remove an existing comment.
 -------------------------------------------------------------------------- */

-(IBAction)	toggleCommentForSelection: (id)sender
{
    NSLog(@"%s", sel_getName(_cmd));
}


/* -----------------------------------------------------------------------------
 validateMenuItem:
 Make sure check marks of the "Toggle auto syntax coloring" and "Maintain
 indentation" menu items are set up properly.
 -------------------------------------------------------------------------- */

-(BOOL)	validateMenuItem:(NSMenuItem*)menuItem
{
//	if( [menuItem action] == @selector(toggleAutoSyntaxColoring:) )
//	{
//		[menuItem setState: [syntaxColoringController autoSyntaxColoring]];
//		return YES;
//	}
//	else if( [menuItem action] == @selector(toggleMaintainIndentation:) )
//	{
//		[menuItem setState: [syntaxColoringController maintainIndentation]];
//		return YES;
//	}
//	else
//		return [super validateMenuItem: menuItem];
	return YES;
}


/* -----------------------------------------------------------------------------
 recolorCompleteFile:
 IBAction to do a complete recolor of the whole friggin' document.
 -------------------------------------------------------------------------- */

-(IBAction)	recolorCompleteFile: (id)sender
{
    NSLog(@"%s", sel_getName(_cmd));
}

-(NSDictionary*)	syntaxDefinitionDictionaryForTextViewController: (id)sender{
	if (!syntaxColoringDictionary){
		syntaxColoringDictionary = [NSDictionary dictionaryWithContentsOfFile: [[NSBundle mainBundle] pathForResource: @"TSQL" ofType:@"plist"]];
	}
	[syntaxColoringDictionary retain];
	return syntaxColoringDictionary;
}

@end
			
