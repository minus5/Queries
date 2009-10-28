#import "CredentialsController.h"

@implementation CredentialsController

- (NSString*) windowNibName{
	return @"CredentialsView";
}

- (id)initWithOwner: (ConnectionController*) o
{
	self = [super init];
	if (self) {
    owner = o;    
		[owner retain];
	}
	return self;
}

- (void) dealloc{
	[super dealloc];
	[owner release];
}

+ (CredentialsController*) controllerWithOwner: (ConnectionController*) o{	
	CredentialsController *controller = [[CredentialsController alloc] initWithOwner:o];
	[controller window];
	return controller;
} 
    
- (void) showSheet{
	[NSApp beginSheet: [self window]
		modalForWindow: [owner window]
		modalDelegate: self 
		didEndSelector: nil 
		contextInfo:nil];
}
                                  
- (IBAction) connect: (id)sender
{                    	
	[self closeSheet]; 
	[owner didChangeConnection: nil];          
} 

- (IBAction) close: (id)sender
{
	[self closeSheet];
}   

- (void) closeSheet{
	[NSApp endSheet: [self window]];
	[[self window] orderOut: self];	
}

@end
