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
	@try {
		TdsConnection *newConnection = [TdsConnection alloc];
		[newConnection initWithCredentials: [server stringValue] 
										 databaseName: [database stringValue] 
												 userName: [username stringValue] 
												 password: [password stringValue] ];	
		[newConnection login];
		[owner didChangeConnection: newConnection];  
		[self closeSheet];
	}
	@catch (NSException * e) {
		NSLog(@"connect error: %@", e);
	}
	@finally {

	}
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
