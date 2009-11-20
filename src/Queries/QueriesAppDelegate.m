#import "QueriesAppDelegate.h"

@implementation QueriesAppDelegate

@synthesize window;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {	
	connections = [[NSMutableArray	array] retain];
	[self newDocument: nil];
}

- (IBAction) newDocument: (id) sender{
	ConnectionController *connectionController = [[ConnectionController alloc] init];
	[connectionController showWindow: nil];	
	[connections addObject: connectionController];
} 
                                                                                      
- (int) numberOfEditedQueries{
	int count = 0;          
	for(ConnectionController *connectionController in connections){
		count += [connectionController numberOfEditedQueries];
	}                             
	return count;
}

- (NSApplicationTerminateReply) applicationShouldTerminate:(NSApplication *) sender{  			        
	int numberOfEditedQuries = [self numberOfEditedQueries];
	if (numberOfEditedQuries > 0){                         
		NSString *message = @"You have unsaved query. Quit anyway?";
		if (numberOfEditedQuries > 1){                                                                                       
			message = [NSString stringWithFormat: @"You have %d unsaved queries. Quit anyway?", numberOfEditedQuries];         
		}   										
		NSAlert *alert = [NSAlert alertWithMessageText: message
			defaultButton: @"Quit"
			alternateButton: @"Don't Quit"
      otherButton: nil								
      informativeTextWithFormat: @"Your changes will be lost if you don't save them."];		

		if ([alert runModal] == NSAlertAlternateReturn){   
			return NSTerminateCancel;		                     
		}
	}	
	return NSTerminateNow;
}

+ (NSString*) sqlFileContent: (NSString*) queryFileName{
	NSString *query = [NSString stringWithContentsOfFile: 
		[[NSBundle mainBundle] pathForResource: queryFileName ofType:@"sql"]
		encoding: NSUTF8StringEncoding
		error: nil
		];
	return query;
}

- (IBAction) userPreferences: (id) sender{
	if (!preferences){
		preferences = [[PreferencesController alloc] init];
	}                                                    
	[preferences showWindow: self];
}                                          

- (void) dealloc{
	[preferences release];
	[connections release];
	[super dealloc];
}                                

#pragma mark ---- register factory defaults ----

+(void) initialize{
	NSMutableDictionary *defaultValues = [NSMutableDictionary dictionary];   					
	[defaultValues setObject:[QueriesAppDelegate connectionDefaults] forKey:	QueriesConnectionDefaults];
	[defaultValues setObject:[NSNumber numberWithInteger: 15] forKey:	QueriesLoginTimeout];
	[defaultValues setObject:[NSNumber numberWithInteger: 0] forKey:	QueriesQueryTimeout];	
	[[NSUserDefaults standardUserDefaults] registerDefaults: defaultValues];
} 

+(NSString*) connectionDefaults{
	return [QueriesAppDelegate sqlFileContent: @"connection_defaults"];
}

@end
