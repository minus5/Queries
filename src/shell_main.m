#import <Foundation/Foundation.h>

#import "ColumnMetadata.h"
#import "TdsConnection.h"
#import "QueryResult.h"
#import "CreateTableScript.h" 
#import "ConnectionsManager.h"


void testCreateTableSctipt(){
	TdsConnection *connection = [TdsConnection alloc];	
	[connection initWithServer: @"mssql.mobilnet.hr" user: @"sa" password: @"", connectionDefaults: @""];
	[connection login];  
	
	NSLog(@"\n%@", [CreateTableScript scriptWithConnection: connection database: @"pubs" table: @"authors"]);
	NSLog(@"\n%@", [CreateTableScript scriptWithConnection: connection database: @"SuperSport" table: @"SlipBetts"]);
	NSLog(@"\n%@", [CreateTableScript scriptWithConnection: connection database: @"SuperSport" table: @"Slips"]);
	                   
	[connection release];
}

void testSelectEncoding(){
	TdsConnection *connection = [TdsConnection alloc];	
	[connection initWithServer: @"mssql.mobilnet.hr" user: @"sa" password: @"", connectionDefaults: @""];
	[connection login];  
	[connection execute: @"use pubs\nselect * from publishers"];
	[connection release];
}

void testQueryResultsRetainCount(){
	TdsConnection *connection = [TdsConnection alloc];	
	[connection initWithServer: @"mssql.mobilnet.hr" user: @"sa" password: @"", connectionDefaults: @""];
	[connection login];
	
	for(size_t i = 0; i < 10; ++i)
	{                       
		NSLog(@"loop %d", i);			
		QueryResult* result = [connection execute: @"select * from pubs.dbo.publishers"];		
		assert([result hasResults]);
		assert([result resultsCount] == 1);	                  
		NSLog(@"result retainCount %d", [result retainCount]);
		[result release];                  		
	}
	[connection release];
}   

void testMaxColumnLength(){
	TdsConnection *connection = [TdsConnection alloc];	
	[connection initWithServer: @"mssql.mobilnet.hr" user: @"sa" password: @"", connectionDefaults: @""];
	[connection login];	                                                                                      
	QueryResult* result = [connection execute: @"use pubs\nexec sp_help 'dbo.publishers'"];			
	
	// NSMutableString *resultString = [NSMutableString string];
	// for(int i = 0; i < [[result columns] count]; ++i)
	// {
	// 	ColumnMetadata *column = [[result columns] objectAtIndex: i];
	// 	[resultString appendFormat: [column formatString], [[column name] UTF8String]];		
	// }
	// [resultString appendFormat: @"\n"];
	// NSArray *rows = [result rows];
	// NSArray *columns = [result columns];
	// for(int r=0; r<[rows count]; r++){		
	// 	for(int c=0; c<[columns count]; c++){
	// 		NSString *value = [[rows objectAtIndex:r] objectAtIndex:c];
	// 		ColumnMetadata *column = [columns objectAtIndex: c];
	// 		[resultString appendFormat: [column formatString], [value UTF8String]];
	// 	}                                                     
	// 	[resultString appendFormat: @"\n"];
	// }  	 	
	// 
	// NSLog(@"\n\n%@\n", resultString);	 
	
	NSLog(@"\n\n%@\n", [result resultsInText]);	
}
    
void testConnectionsManager(){
	ConnectionsManager *manager = [ConnectionsManager sharedInstance];
	
	//returns same connection 
	TdsConnection *c1 = [manager connectionToServer:@"mssql" withUser:@"ianic" andPassword:@"string"];
	TdsConnection *c12 = [manager connectionToServer:@"mssql" withUser:@"ianic" andPassword:@"string"];
	TdsConnection *c13 = [manager connectionWithName:@"ianic@mssql"];
	assert(c1 == c12);
	assert(c1 == c13);
	assert(1 == [manager connectionsCount: @"ianic@mssql"]); 
	         
	//returns cloned connection when original is busy
	[c1 executeInBackground: @"begin\nWAITFOR DELAY '00:00:02'\nend" withDatabase: @"pubs" returnToObject: nil withSelector: nil]; 	
	[NSThread sleepForTimeInterval: 1]; 	
	TdsConnection *c3 = [manager connectionWithName:@"ianic@mssql"];
	TdsConnection *c31 = [manager connectionToServer:@"mssql" withUser:@"ianic" andPassword:@"string"];
	assert(c3 != c1);   
	assert(c31 == c3);   
	assert(2 == [manager connectionsCount: @"ianic@mssql"]);
		                                               
	//cleanup clears all inactive cloned connectins
	[NSThread sleepForTimeInterval:2]; 	
	[manager cleanup];
	assert(1 == [manager connectionsCount: @"ianic@mssql"]);
		                                             
	[ConnectionsManager releaseSharedInstance];
}   

void testRegex(){
	NSString *query = @"iso\n GO \nmedo\n  go  \nu ducan (mozda se zvao gogo)\na mozda I GOGO\ngo\nnije reko dobar dan";
	NSString *regexString  = @"^\\s*go\\s*$";			
	NSArray *queries = [query componentsSeparatedByRegex:regexString options: (2 | 8) range: NSMakeRange(0, [query length]) error:nil];
		
	assert(4 == [queries count]);                                       
	NSLog(@"queries count: %d", [queries count]);
	NSLog(@"queries: %@", queries);
	
	query = @"iso medo u ducan\nnije reko dobar dan\n";                                                                      
	queries = [query componentsSeparatedByRegex:regexString options: (2 | 8) range: NSMakeRange(0, [query length]) error:nil];
	assert(1 == [queries count]);	                                                                                                                    
	NSLog(@"queries: %@", queries);
}

int main (int argc, const char * argv[]) {	
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];  
	NSLog(@"uses garbage collection %d", [NSGarbageCollector defaultCollector] != nil);
	
	//testQueryResultsRetainCount();
	//testCreateTableSctipt();
	//testMaxColumnLength();
	//testSelectEncoding();
	//testConnectionsManager();
	testRegex();
	
	NSLog(@"shell test finished...");
	[pool drain];
	return 0;
} 
                                  

