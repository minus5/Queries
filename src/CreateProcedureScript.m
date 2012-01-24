#import "CreateProcedureScript.h"

@implementation CreateProcedureScript

- (id) initWithConnection: (TdsConnection*) c  
								 database: (NSString*) d 
									 object: (NSString*) o
										 type: (NSString*) t
								 receiver: (id) r
								 selector: (SEL) s
{
	if (self = [super init]){
		connection	= [c retain];
		database		= [d retain];
		object			= [o retain];
		type        = [t retain];
		receiver		= [r retain];
		selector		= s;		
	}
	return self;
} 

- (void) generate{
	NSString *query = [NSString stringWithFormat: @"use %@\nselect text from syscomments where id = object_id('%@')", database, object];
	[connection executeInBackground: query
										 withDatabase: database
									 returnToObject: self 
										 withSelector: @selector(setResult:)];
}

- (void) setResult: (QueryResult*) result{
	
	NSString *script = [result resultAsString];                                                                             				
	NSString *createRegexString = [NSString stringWithFormat: @"(?im)(^\\s*CREATE\\s+%@\\s+)", type]; 
	NSString *alterRegexString = [NSString stringWithFormat: @"ALTER %@ ", type]; 
	script = [script stringByReplacingOccurrencesOfRegex:createRegexString withString:alterRegexString];                                        
		
	[receiver performSelectorOnMainThread: selector 
														 withObject: [NSArray arrayWithObjects: script, object, nil]
													waitUntilDone: YES];		
}
                                                                
- (void) dealloc{       	
	[connection release];
	[database release];
	[object release];
	[type release];
	[receiver release];

	[super dealloc];
}

@end


