#import <Cocoa/Cocoa.h>
#import "QueryController.h"
#import "NSArray+Color.h"
#import "NSScanner+SkipUpToCharset.h"

@implementation QueryController (SyntaxHighlight)


-(void) syntaxColoringInit{
	syntaxColoringAuto = YES;
	syntaxColoringMaintainIndentation = YES;
	syntaxColoringBusy = NO;
	
	//TODO ovo sam iskljucio jer se inace raspadne kod indent/unindent
	//syntaxColoringUndoManger = [[NSUndoManager alloc] init];
	
	// Register for "text changed" notifications of our text storage:
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(processEditing:)
																							 name: NSTextStorageDidProcessEditingNotification
																						 object: [syntaxColoringTextView textStorage]];	
}

- (NSUndoManager *)undoManagerForTextView:(NSTextView *)aTextView{
	return syntaxColoringUndoManger;
}

- (BOOL) isInUndo{
	return [syntaxColoringUndoManger isUndoing] || [syntaxColoringUndoManger isRedoing];
}

/* -----------------------------------------------------------------------------
 recolorRange:
 Try to apply syntax coloring to the text in our text view. This
 overwrites any styles the text may have had before. This function
 guarantees that it'll preserve the selection.
 
 Note that the order in which the different things are colorized is
 important. E.g. identifiers go first, followed by comments, since that
 way colors are removed from identifiers inside a comment and replaced
 with the comment color, etc. 
 
 The range passed in here is special, and may not include partial
 identifiers or the end of a comment. Make sure you include the entire
 multi-line comment etc. or it'll lose color.
 
 This calls oldRecolorRange to handle old-style syntax definitions.
 -------------------------------------------------------------------------- */
-(void) recolorRange: (NSRange)range
{
	if( syntaxColoringBusy )	// Prevent endless loop when recoloring's replacement of text causes processEditing to fire again.
		return;
	
	if( syntaxColoringTextView == nil || range.length == 0)	// Don't like doing useless stuff.
		//		 || recolorTimer )						// And don't like recoloring partially if a full recolorization is pending.
		return;
	
	// Kludge fix for case where we sometimes exceed text length:ra
	int diff = [[syntaxColoringTextView textStorage] length] -(range.location +range.length);
	if( diff < 0 )
		range.length += diff;
	
	NS_DURING
	syntaxColoringBusy = YES;
	//	[progress startAnimation:nil];
	
	[syntaxColoringStatus setStringValue: [NSString stringWithFormat: @"Recoloring syntax in %@", NSStringFromRange(range)]];
	
	// Get the text we'll be working with:
	//NSRange						vOldSelection = [syntaxColoringTextView selectedRange];
	NSMutableAttributedString*	vString = [[NSMutableAttributedString alloc] initWithString: [[[syntaxColoringTextView textStorage] string] substringWithRange: range]];
	[vString autorelease];
	
	// Load colors and fonts to use from preferences:
	
	// Load our dictionary which contains info on coloring this language:
	NSDictionary*				vSyntaxDefinition = [self syntaxDefinitionDictionary];
	NSEnumerator*				vComponentsEnny = [[vSyntaxDefinition objectForKey: @"Components"] objectEnumerator];
	
	if( vComponentsEnny == nil )	// No new-style list of components to colorize? Use old code.
	{
		NS_VOIDRETURN;
	}
	
	// Loop over all available components:
	NSDictionary*				vCurrComponent = nil;
	NSDictionary*				vStyles = [self defaultTextAttributes];
	NSUserDefaults*				vPrefs = [NSUserDefaults standardUserDefaults];
	
	while( (vCurrComponent = [vComponentsEnny nextObject]) )
	{
		NSString*   vComponentType = [vCurrComponent objectForKey: @"Type"];
		NSString*   vComponentName = [vCurrComponent objectForKey: @"Name"];
		NSString*   vColorKeyName = [@"SyntaxColoring:Color:" stringByAppendingString: vComponentName];
		NSColor*	vColor = [[vPrefs arrayForKey: vColorKeyName] colorValue];
		
		if( !vColor )
			vColor = [[vCurrComponent objectForKey: @"Color"] colorValue];
		
		if( [vComponentType isEqualToString: @"BlockComment"] )
		{
			[self colorCommentsFrom: [vCurrComponent objectForKey: @"Start"]
													 to: [vCurrComponent objectForKey: @"End"] inString: vString
										withColor: vColor andMode: vComponentName];
		}
		else if( [vComponentType isEqualToString: @"OneLineComment"] )
		{
			[self colorOneLineComment: [vCurrComponent objectForKey: @"Start"]
											 inString: vString withColor: vColor andMode: vComponentName];
		}
		else if( [vComponentType isEqualToString: @"String"] )
		{
			[self colorStringsFrom: [vCurrComponent objectForKey: @"Start"]
													to: [vCurrComponent objectForKey: @"End"]
										inString: vString withColor: vColor andMode: vComponentName
							 andEscapeChar: [vCurrComponent objectForKey: @"EscapeChar"]]; 
		}
		else if( [vComponentType isEqualToString: @"Tag"] )
		{
			[self colorTagFrom: [vCurrComponent objectForKey: @"Start"]
											to: [vCurrComponent objectForKey: @"End"] inString: vString
							 withColor: vColor andMode: vComponentName
						exceptIfMode: [vCurrComponent objectForKey: @"IgnoredComponent"]];
		}
		else if( [vComponentType isEqualToString: @"Keywords"] )
		{
			NSArray* vIdents = [vCurrComponent objectForKey: @"Keywords"];
			if( !vIdents )
				vIdents = [[NSUserDefaults standardUserDefaults] objectForKey: [@"SyntaxColoring:Keywords:" stringByAppendingString: vComponentName]];
			if( !vIdents && [vComponentName isEqualToString: @"UserIdentifiers"] )
				vIdents = [[NSUserDefaults standardUserDefaults] objectForKey: TD_USER_DEFINED_IDENTIFIERS];
			if( vIdents )
			{
				NSCharacterSet*		vIdentCharset = nil;
				NSString*			vCurrIdent = nil;
				NSString*			vCsStr = [vCurrComponent objectForKey: @"Charset"];
				if( vCsStr )
					vIdentCharset = [NSCharacterSet characterSetWithCharactersInString: vCsStr];
				
				NSEnumerator*	vItty = [vIdents objectEnumerator];
				while( vCurrIdent = [vItty nextObject] )
					[self colorIdentifier: vCurrIdent inString: vString withColor: vColor
												andMode: vComponentName charset: vIdentCharset];
			}
		}
	}
	
	// Replace the range with our recolored part:
	[vString addAttributes: vStyles range: NSMakeRange( 0, [vString length] )];
	[[syntaxColoringTextView textStorage] replaceCharactersInRange: range withAttributedString: vString];
	
	syntaxColoringBusy = NO;
	NS_HANDLER
	syntaxColoringBusy = NO;
	[localException raise];
	NS_ENDHANDLER
}

/* -----------------------------------------------------------------------------
 colorStringsFrom:
 Apply syntax coloring to all strings. This is basically the same code
 as used for multi-line comments, except that it ignores the end
 character if it is preceded by a backslash.
 -------------------------------------------------------------------------- */
-(void)	colorStringsFrom: (NSString*) startCh to: (NSString*) endCh inString: (NSMutableAttributedString*) s
							 withColor: (NSColor*) col andMode:(NSString*)attr andEscapeChar: (NSString*)vStringEscapeCharacter
{
	NS_DURING
	NSScanner*					vScanner = [NSScanner scannerWithString: [s string]];
	NSDictionary*				vStyles = [NSDictionary dictionaryWithObjectsAndKeys:
																 col, NSForegroundColorAttributeName,
																 attr, TD_SYNTAX_COLORING_MODE_ATTR,
																 nil];
	BOOL						vIsEndChar = NO;
	unichar						vEscChar = '\\';
	
	if( vStringEscapeCharacter )
	{
		if( [vStringEscapeCharacter length] != 0 )
			vEscChar = [vStringEscapeCharacter characterAtIndex: 0];
	}
	
	while( ![vScanner isAtEnd] )
	{
		int		vStartOffs,
		vEndOffs;
		vIsEndChar = NO;
		
		// Look for start of string:
		[vScanner scanUpToString: startCh intoString: nil];
		vStartOffs = [vScanner scanLocation];
		if( ![vScanner scanString:startCh intoString:nil] )
			NS_VOIDRETURN;
		
		while( !vIsEndChar && ![vScanner isAtEnd] )	// Loop until we find end-of-string marker or our text to color is finished:
		{
			[vScanner scanUpToString: endCh intoString: nil];
			if( ([vStringEscapeCharacter length] == 0) || [[s string] characterAtIndex: ([vScanner scanLocation] -1)] != vEscChar )	// Backslash before the end marker? That means ignore the end marker.
				vIsEndChar = YES;	// A real one! Terminate loop.
			if( ![vScanner scanString:endCh intoString:nil] )	// But skip this char before that.
				NS_VOIDRETURN;
			
			//			[progress animate:nil];
		}
		
		vEndOffs = [vScanner scanLocation];
		
		// Now mess with the string's styles:
		[s setAttributes: vStyles range: NSMakeRange( vStartOffs, vEndOffs -vStartOffs )];
	}
	NS_HANDLER
	// Just ignore it, syntax coloring isn't that important.
	NS_ENDHANDLER
}

/* -----------------------------------------------------------------------------
 colorCommentsFrom:
 Colorize block-comments in the text view.
 
 REVISIONS:
 2004-05-18  witness Documented.
 -------------------------------------------------------------------------- */
-(void)	colorCommentsFrom: (NSString*) startCh to: (NSString*) endCh inString: (NSMutableAttributedString*) s
								withColor: (NSColor*) col andMode:(NSString*)attr
{
	NS_DURING
	NSScanner*					vScanner = [NSScanner scannerWithString: [s string]];
	NSDictionary*				vStyles = [NSDictionary dictionaryWithObjectsAndKeys:
																 col, NSForegroundColorAttributeName,
																 attr, TD_SYNTAX_COLORING_MODE_ATTR,
																 nil];
	
	while( ![vScanner isAtEnd] )
	{
		int		vStartOffs,
		vEndOffs;
		
		// Look for start of multi-line comment:
		[vScanner scanUpToString: startCh intoString: nil];
		vStartOffs = [vScanner scanLocation];
		if( ![vScanner scanString:startCh intoString:nil] )
			NS_VOIDRETURN;
		
		// Look for associated end-of-comment marker:
		[vScanner scanUpToString: endCh intoString: nil];
		if( ![vScanner scanString:endCh intoString:nil] )
		/*NS_VOIDRETURN*/;  // Don't exit. If user forgot trailing marker, indicate this by "bleeding" until end of string.
		vEndOffs = [vScanner scanLocation];
		
		// Now mess with the string's styles:
		[s setAttributes: vStyles range: NSMakeRange( vStartOffs, vEndOffs -vStartOffs )];
		
		//		[progress animate:nil];
	}
	NS_HANDLER
	// Just ignore it, syntax coloring isn't that important.
	NS_ENDHANDLER
}

/* -----------------------------------------------------------------------------
 colorOneLineComment:
 Colorize one-line-comments in the text view.
 
 REVISIONS:
 2004-05-18  witness Documented.
 -------------------------------------------------------------------------- */
-(void)	colorOneLineComment: (NSString*) startCh inString: (NSMutableAttributedString*) s
									withColor: (NSColor*) col andMode:(NSString*)attr
{
	NS_DURING
	NSScanner*					vScanner = [NSScanner scannerWithString: [s string]];
	NSDictionary*				vStyles = [NSDictionary dictionaryWithObjectsAndKeys:
																 col, NSForegroundColorAttributeName,
																 attr, TD_SYNTAX_COLORING_MODE_ATTR,
																 nil];
	
	while( ![vScanner isAtEnd] )
	{
		int		vStartOffs,
		vEndOffs;
		
		// Look for start of one-line comment:
		[vScanner scanUpToString: startCh intoString: nil];
		vStartOffs = [vScanner scanLocation];
		if( ![vScanner scanString:startCh intoString:nil] )
			NS_VOIDRETURN;
		
		// Look for associated line break:
		if( ![vScanner skipUpToCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString: @"\n\r"]] )
			;
		
		vEndOffs = [vScanner scanLocation];
		
		// Now mess with the string's styles:
		[s setAttributes: vStyles range: NSMakeRange( vStartOffs, vEndOffs -vStartOffs )];
		
		//		[progress animate:nil];
	}
	NS_HANDLER
	// Just ignore it, syntax coloring isn't that important.
	NS_ENDHANDLER
}

/* -----------------------------------------------------------------------------
 colorIdentifier:
 Colorize keywords in the text view.
 
 REVISIONS:
 2004-05-18  witness Documented.
 -------------------------------------------------------------------------- */
-(void)	colorIdentifier: (NSString*) ident inString: (NSMutableAttributedString*) s
							withColor: (NSColor*) col andMode:(NSString*)attr charset: (NSCharacterSet*)cset
{
	NS_DURING
	NSScanner*					vScanner = [NSScanner scannerWithString: [s string]];
	NSDictionary*				vStyles = [NSDictionary dictionaryWithObjectsAndKeys:
																 col, NSForegroundColorAttributeName,
																 attr, TD_SYNTAX_COLORING_MODE_ATTR,
																 nil];
	int							vStartOffs = 0;
	
	// Skip any leading whitespace chars, somehow NSScanner doesn't do that:
	if( cset )
	{
		while( vStartOffs < [[s string] length] )
		{
			if( [cset characterIsMember: [[s string] characterAtIndex: vStartOffs]] )
				break;
			vStartOffs++;
		}
	}
	
	[vScanner setScanLocation: vStartOffs];
	
	while( ![vScanner isAtEnd] )
	{
		// Look for start of identifier:
		[vScanner scanUpToString: ident intoString: nil];
		vStartOffs = [vScanner scanLocation];
		if( ![vScanner scanString:ident intoString:nil] )
			NS_VOIDRETURN;
		
		if( vStartOffs > 0 )	// Check that we're not in the middle of an identifier:
		{
			// Alphanum character before identifier start?
			if( [cset characterIsMember: [[s string] characterAtIndex: (vStartOffs -1)]] )  // If charset is NIL, this evaluates to NO.
				continue;
		}
		
		if( (vStartOffs +[ident length] +1) < [s length] )
		{
			// Alphanum character following our identifier?
			if( [cset characterIsMember: [[s string] characterAtIndex: (vStartOffs +[ident length])]] )  // If charset is NIL, this evaluates to NO.
				continue;
		}
		
		// Now mess with the string's styles:
		[s setAttributes: vStyles range: NSMakeRange( vStartOffs, [ident length] )];
		
		//		[progress animate:nil];
	}
	
	NS_HANDLER
	// Just ignore it, syntax coloring isn't that important.
	NS_ENDHANDLER
}

/* -----------------------------------------------------------------------------
 colorTagFrom:
 Colorize HTML tags or similar constructs in the text view.
 
 REVISIONS:
 2004-05-18  witness Documented.
 -------------------------------------------------------------------------- */
-(void)	colorTagFrom: (NSString*) startCh to: (NSString*)endCh inString: (NSMutableAttributedString*) s
					 withColor: (NSColor*) col andMode:(NSString*)attr exceptIfMode: (NSString*)ignoreAttr
{
	NS_DURING
	NSScanner*					vScanner = [NSScanner scannerWithString: [s string]];
	NSDictionary*				vStyles = [NSDictionary dictionaryWithObjectsAndKeys:
																 col, NSForegroundColorAttributeName,
																 attr, TD_SYNTAX_COLORING_MODE_ATTR,
																 nil];
	
	while( ![vScanner isAtEnd] )
	{
		int		vStartOffs,
		vEndOffs;
		
		// Look for start of one-line comment:
		[vScanner scanUpToString: startCh intoString: nil];
		vStartOffs = [vScanner scanLocation];
		if( vStartOffs >= [s length] )
			NS_VOIDRETURN;
		NSString*   scMode = [[s attributesAtIndex:vStartOffs effectiveRange: nil] objectForKey: TD_SYNTAX_COLORING_MODE_ATTR];
		if( ![vScanner scanString:startCh intoString:nil] )
			NS_VOIDRETURN;
		
		// If start lies in range of ignored style, don't colorize it:
		if( ignoreAttr != nil && [scMode isEqualToString: ignoreAttr] )
			continue;
		
		// Look for matching end marker:
		while( ![vScanner isAtEnd] )
		{
			// Scan up to the next occurence of the terminating sequence:
			(BOOL) [vScanner scanUpToString: endCh intoString:nil];
			
			// Now, if the mode of the end marker is not the mode we were told to ignore,
			//  we're finished now and we can exit the inner loop:
			vEndOffs = [vScanner scanLocation];
			if( vEndOffs < [s length] )
			{
				scMode = [[s attributesAtIndex:vEndOffs effectiveRange: nil] objectForKey: TD_SYNTAX_COLORING_MODE_ATTR];
				[vScanner scanString: endCh intoString: nil];   // Also skip the terminating sequence.
				if( ignoreAttr == nil || ![scMode isEqualToString: ignoreAttr] )
					break;
			}
			
			// Otherwise we keep going, look for the next occurence of endCh and hope it isn't in that style.
		}
		
		vEndOffs = [vScanner scanLocation];
		
		// Now mess with the string's styles:
		[s setAttributes: vStyles range: NSMakeRange( vStartOffs, vEndOffs -vStartOffs )];
		
		//		[progress animate:nil];
	}
	NS_HANDLER
	// Just ignore it, syntax coloring isn't that important.
	NS_ENDHANDLER
}

/* -----------------------------------------------------------------------------
 syntaxDefinitionDictionary:
 This returns the syntax definition dictionary to use, which indicates
 what ranges of text to colorize. Advanced users may use this to allow
 different coloring to take place depending on the file extension by
 returning different dictionaries here.
 
 By default, this simply reads a dictionary from the .plist file
 indicated by -syntaxDefinitionFilename.
 -------------------------------------------------------------------------- */
-(NSDictionary*)	syntaxDefinitionDictionary
{
	if (!syntaxColoringDictionary){
		syntaxColoringDictionary = [NSDictionary dictionaryWithContentsOfFile: [[NSBundle mainBundle] pathForResource: @"TSQL" ofType:@"plist"]];
	}
	[syntaxColoringDictionary retain];
	return syntaxColoringDictionary;
}

/* -----------------------------------------------------------------------------
 defaultTextAttributes:
 Return the text attributes to use for the text in our text view.
 
 REVISIONS:
 2004-05-18  witness Documented.
 -------------------------------------------------------------------------- */
-(NSDictionary*)	defaultTextAttributes
{
	return [NSDictionary dictionaryWithObject:[NSFont userFixedPitchFontOfSize:[NSFont smallSystemFontSize]] forKey: NSFontAttributeName];
}

/* -----------------------------------------------------------------------------
 processEditing:
 Part of the text was changed. Recolor it.
 -------------------------------------------------------------------------- */
-(void) processEditing: (NSNotification*)notification
{
	NSTextStorage	*textStorage = [notification object];
	NSRange			range = [textStorage editedRange];
	int				changeInLen = [textStorage changeInLength];
	BOOL			wasInUndoRedo = [self isInUndo];
	BOOL			textLengthMayHaveChanged = NO;
	
	// Was delete op or undo that could have changed text length?
	if( wasInUndoRedo )
	{
		return;
//#warning ovo sam morao iskljuciti jer se inace zblesa
		textLengthMayHaveChanged = YES;
		range = [syntaxColoringTextView selectedRange];							
	}
	if( changeInLen <= 0 )
		textLengthMayHaveChanged = YES;
	
	//	Try to get chars around this to recolor any identifier we're in:
	if( textLengthMayHaveChanged )
	{
		if( range.location > 0 )
			range.location--;
		if( (range.location +range.length +2) < [textStorage length] )
			range.length += 2;
		else if( (range.location +range.length +1) < [textStorage length] )
			range.length += 1;
	}
	
	NSRange						currRange = range;
	
	// Perform the syntax coloring:
	if( syntaxColoringAuto && range.length > 0 )
	{
		NSRange			effectiveRange;
		NSString*		rangeMode;
		
		
		rangeMode = [textStorage attribute: TD_SYNTAX_COLORING_MODE_ATTR
															 atIndex: currRange.location
												effectiveRange: &effectiveRange];
		
		unsigned int		x = range.location;
		
		/* TODO: If we're in a multi-line comment and we're typing a comment-end
		 character, or we're in a string and we're typing a quote character,
		 this should include the rest of the text up to the next comment/string
		 end character in the recalc. */
		
		// Scan up to prev line break:
		while( x > 0 )
		{
			unichar theCh = [[textStorage string] characterAtIndex: x];
			if( theCh == '\n' || theCh == '\r' )
				break;
			--x;
		}
		
		currRange.location = x;
		
		// Scan up to next line break:
		x = range.location +range.length;
		
		while( x < [textStorage length] )
		{
			unichar theCh = [[textStorage string] characterAtIndex: x];
			if( theCh == '\n' || theCh == '\r' )
				break;
			++x;
		}
		
		currRange.length = x -currRange.location;
		
		// Open identifier, comment etc.? Make sure we include the whole range.
		if( rangeMode != nil )
			currRange = NSUnionRange( currRange, effectiveRange );
		
		// Actually recolor the changed part:
		[self recolorRange: currRange];
	}
}

-(void)	didChangeText	// This actually does what we want to do in textView:shouldChangeTextInRange:
{
	if( syntaxColoringMaintainIndentation && syntaxColoringReplacementString && ([syntaxColoringReplacementString isEqualToString:@"\n"]
																																							 || [syntaxColoringReplacementString isEqualToString:@"\r"]) )
	{
		NSMutableAttributedString*  textStore = [syntaxColoringTextView textStorage];
		BOOL						hadSpaces = NO;
		unsigned int				lastSpace = syntaxColoringAffectedCharRange.location,
		prevLineBreak = 0;
		NSRange						spacesRange = { 0, 0 };
		unichar						theChar = 0;
		unsigned int				x = (syntaxColoringAffectedCharRange.location == 0) ? 0 : syntaxColoringAffectedCharRange.location -1;
		NSString*					tsString = [textStore string];
		
		while( true )
		{
			if( x > ([tsString length] -1) )
				break;
			
			theChar = [tsString characterAtIndex: x];
			
			switch( theChar )
			{
				case '\n':
				case '\r':
					prevLineBreak = x +1;
					x = 0;  // Terminate the loop.
					break;
					
				case ' ':
				case '\t':
					if( !hadSpaces )
					{
						lastSpace = x;
						hadSpaces = YES;
					}
					break;
					
				default:
					hadSpaces = NO;
					break;
			}
			
			if( x == 0 )
				break;
			
			x--;
		}
		
		if( hadSpaces )
		{
			spacesRange.location = prevLineBreak;
			spacesRange.length = lastSpace -prevLineBreak +1;
			if( spacesRange.length > 0 )
				[syntaxColoringTextView insertText: [tsString substringWithRange:spacesRange]];
		}
	}
}

/* -----------------------------------------------------------------------------
 textView:willChangeSelectionFromCharacterRange:toCharacterRange:
 Delegate method called when our selection changes. Updates our status
 display to indicate which characters are selected.
 -------------------------------------------------------------------------- */
-(NSRange)  textView: (NSTextView*)theTextView willChangeSelectionFromCharacterRange: (NSRange)oldSelectedCharRange
		toCharacterRange:(NSRange)newSelectedCharRange
{
	unsigned		startCh = newSelectedCharRange.location +1,
	endCh = newSelectedCharRange.location +newSelectedCharRange.length;
	unsigned		lineNo = 1,
	lastLineStart = 0,
	x;
	unsigned		startChLine, endChLine;
	unichar			lastBreakChar = 0;
	unsigned		lastBreakOffs = 0;
	
	// Calc line number:
	for( x = 0; (x < startCh) && (x < [[theTextView string] length]); x++ )
	{
		unichar		theCh = [[theTextView string] characterAtIndex: x];
		switch( theCh )
		{
			case '\n':
				if( lastBreakOffs == (x-1) && lastBreakChar == '\r' )   // LF in CRLF sequence? Treat this as a single line break.
				{
					lastBreakOffs = 0;
					lastBreakChar = 0;
					continue;
				}
				// Else fall through!
				
			case '\r':
				lineNo++;
				lastLineStart = x +1;
				lastBreakOffs = x;
				lastBreakChar = theCh;
				break;
		}
	}
	
	startChLine = (newSelectedCharRange.location -lastLineStart) +1;
	endChLine = (newSelectedCharRange.location -lastLineStart) +newSelectedCharRange.length;
	
	NSImage*	img = nil;
	
	// Display info:
	if( startCh > endCh )   // Insertion mark!
	{
		img = [NSImage imageNamed: @"InsertionMark"];
		[syntaxColoringStatus setStringValue: [NSString stringWithFormat: @"char %u, line %u (char %u in document)", startChLine, lineNo, startCh]];
	}
	else					// Selection
	{
		img = [NSImage imageNamed: @"SelectionRange"];
		[syntaxColoringStatus setStringValue: [NSString stringWithFormat: @"char %u to %u, line %u (char %u to %u in document)", startChLine, endChLine, lineNo, startCh, endCh]];
	}
	
	//[selectionKindImage setImage: img];
	
	return newSelectedCharRange;
}

/* -----------------------------------------------------------------------------
 textView:shouldChangeTextinRange:replacementString:
 Perform indentation-maintaining if we're supposed to.
 -------------------------------------------------------------------------- */
-(BOOL) textView:(NSTextView *)tv shouldChangeTextInRange:(NSRange)afcr replacementString:(NSString *)rps
{
	if( syntaxColoringMaintainIndentation )
	{
		syntaxColoringAffectedCharRange = afcr;
		if( syntaxColoringReplacementString )
		{
			[syntaxColoringReplacementString release];
			syntaxColoringReplacementString = nil;
		}
		syntaxColoringReplacementString = [rps retain];
		
		[self performSelector: @selector(didChangeText) withObject: nil afterDelay: 0.0];	// Queue this up on the event loop. If we change the text here, we only confuse the undo stack.
	}
	
	return YES;
}


-(IBAction) indentSelection: (id)sender
{
	[syntaxColoringUndoManger registerUndoWithTarget: self selector: @selector(unindentSelection:) object: nil];
	
	NSRange				selRange = [syntaxColoringTextView selectedRange],
	nuSelRange = selRange;
	unsigned			x;
	NSMutableString*	str = [[syntaxColoringTextView textStorage] mutableString];
	
	// Unselect any trailing returns so we don't indent the next line after a full-line selection.
	if( selRange.length > 1 && ([str characterAtIndex: selRange.location +selRange.length -1] == '\n'
															|| [str characterAtIndex: selRange.location +selRange.length -1] == '\r') )
		selRange.length--;
	
	for( x = selRange.location +selRange.length -1; x >= selRange.location; x-- )
	{
		if( [str characterAtIndex: x] == '\n'
			 || [str characterAtIndex: x] == '\r' )
		{
			[str insertString: @"\t" atIndex: x+1];
			nuSelRange.length++;
		}
		
		if( x == 0 )
			break;
	}
	
	[str insertString: @"\t" atIndex: nuSelRange.location];
	nuSelRange.length++;
	[syntaxColoringTextView setSelectedRange: nuSelRange];
}

-(IBAction) unIndentSelection: (id)sender
{
	NSRange				selRange = [syntaxColoringTextView selectedRange],
	nuSelRange = selRange;
	unsigned			x, n;
	unsigned			lastIndex = selRange.location +selRange.length -1;
	NSMutableString*	str = [[syntaxColoringTextView textStorage] mutableString];
	
	// Unselect any trailing returns so we don't indent the next line after a full-line selection.
	if( selRange.length > 1 && ([str characterAtIndex: selRange.location +selRange.length -1] == '\n'
															|| [str characterAtIndex: selRange.location +selRange.length -1] == '\r') )
		selRange.length--;
	
	if( selRange.length == 0 )
		return;
	
	
	[syntaxColoringUndoManger registerUndoWithTarget: self selector: @selector(indentSelection:) object: nil];
	
	for( x = lastIndex; x >= selRange.location; x-- )
	{
		if( [str characterAtIndex: x] == '\n'
			 || [str characterAtIndex: x] == '\r' )
		{
			if( (x +1) <= lastIndex)
			{
				if( [str characterAtIndex: x+1] == '\t' )
				{
					[str deleteCharactersInRange: NSMakeRange(x+1,1)];
					nuSelRange.length--;
				}
				else
				{
					for( n = x+1; (n <= (x+4)) && (n <= lastIndex); n++ )
					{
						if( [str characterAtIndex: x+1] != ' ' )
							break;
						[str deleteCharactersInRange: NSMakeRange(x+1,1)];
						nuSelRange.length--;
					}
				}
			}
		}
		
		if( x == 0 )
			break;
	}
	
	if( [str characterAtIndex: nuSelRange.location] == '\t' )
	{
		[str deleteCharactersInRange: NSMakeRange(nuSelRange.location,1)];
		nuSelRange.length--;
	}
	else
	{
		for( n = 1; (n <= 4) && (n <= lastIndex); n++ )
		{
			if( [str characterAtIndex: nuSelRange.location] != ' ' )
				break;
			[str deleteCharactersInRange: NSMakeRange(nuSelRange.location,1)];
			nuSelRange.length--;
		}
	}
	
	[syntaxColoringTextView setSelectedRange: nuSelRange];
}

/* -----------------------------------------------------------------------------
 recolorCompleteFile:
 IBAction to do a complete recolor of the whole friggin' document.
 This is called once after the document's been loaded and leaves some
 custom styles in the document which are used by recolorRange to properly
 perform recoloring of parts.
 -------------------------------------------------------------------------- */
-(IBAction)	recolorCompleteFile: (id)sender
{
	NSRange		range = NSMakeRange(0,[[syntaxColoringTextView textStorage] length]);
	[self recolorRange: range];
}


@end
