#import "ConnectionsManager.h"

@implementation ConnectionsManager         

static ConnectionsManager *manager = nil;

+ (ConnectionsManager*) sharedInstance{	
	if (!manager){
		manager = [[[self class] alloc] init];
	}
	return manager;
}

+ (void) releaseSharedInstance{
	[manager release];
	manager = nil;
}

- (id)init
{
	if((self = [super init]))
	{                                
		pool = [[NSMutableDictionary alloc] init];
	}
	return self;
}

- (void) add:(TdsConnection*) newConnection{
	NSMutableArray *connections = [pool objectForKey: [newConnection connectionName]];
	if (!connections){
		connections = [NSMutableArray array];  
		[pool setValue: connections forKey: [newConnection connectionName]];		
	} 
	[connections addObject: newConnection];	 
	//NSLog(@"added new connection to the pool [%@ add:%@] connectionsCount: %d", [self class], [newConnection connectionName], [self connectionsCount: [newConnection connectionName]]);	
} 

- (int) connectionsCount: (NSString*) connectionName{
	NSArray *connections = [pool objectForKey: connectionName];
	if (!connections)
		return 0;
	else
		return [connections count];
}                      

- (TdsConnection*) connectionToServer: (NSString*) server  withUser: (NSString*) user andPassword: (NSString*) password{
	@try{
		TdsConnection *existing = [self connectionWithName: [NSString stringWithFormat:@"%@@%@", user, server]];
		if (existing){ 
			//NSLog(@"returning connection from pool [%@ connectionToServer:%@  withUser:%@ andPassword:%@]", [self class], server, user, password);
			return existing;
		}
		
		TdsConnection *newConenction = [[TdsConnection alloc] 
			initWithServer:server 
			user:user 
			password:password 
			connectionDefaults: [ConnectionsManager sqlFileContent: @"connection_defaults"]
			];
		[newConenction login];
		[self add: newConenction];  
		[newConenction release];
		return newConenction;
	}
	@catch(NSException *e){  
		NSLog(@"[%@ connectionTo:%@  withUser:%@ exception:%@]", [self class], server, user, e);
		return nil;
	}		
}                                                        
                                                                                                              
- (TdsConnection*) connectionWithName: (NSString*) connectionName{  
	@try{
		NSArray *connections = [pool objectForKey: connectionName];
		if (connections){
			for(TdsConnection *c in connections){ 
				if (![c isProcessing]){
					NSLog(@"returning connection from pool [%@ connectionWithName:%@]", [self class], connectionName);
					return c;             
				}
			}                                         			
			TdsConnection *clone = [[connections objectAtIndex: 0] clone];  
			NSLog(@"cloning connection %@", [clone connectionName]);
			[clone login]; 
			[self add: clone]; 
			[clone release]; 		
			return clone;		
		}
		return nil;			
	}
	@catch(NSException *e){  
		NSLog(@"[%@ connectionWithName:%@ exception]%@", [self class], connectionName, e);
		return nil;
	}
}  

-(void) cleanup{
	for(NSMutableArray *connections in [pool allValues]){
		if ([connections count] > 1){
			for(int i=[connections count]-1; i>0; i--){
				TdsConnection *c = [connections objectAtIndex: i];
				if (![c isProcessing])
					[connections removeObjectAtIndex: i];
			}
		}
	}
}  

- (void) dealloc{     
	//NSLog(@"[%@ dealloc] start", [self class]);
	for(NSMutableArray *connections in [pool allValues]){             
		[connections removeAllObjects];
	}	
	[pool removeAllObjects];
	[pool release];
	[super dealloc];                     
	//NSLog(@"[%@ dealloc] end", [self class]);
}   

+ (NSString*) sqlFileContent: (NSString*) queryFileName{
	NSString *query = [NSString stringWithContentsOfFile: 
		[[NSBundle mainBundle] pathForResource: queryFileName ofType:@"sql"]
		encoding: NSUTF8StringEncoding
		error: nil
		];
	return query;
}

@end