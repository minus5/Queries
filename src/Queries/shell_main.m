#import <Foundation/Foundation.h>

#import "ColumnMetadata.h"
#import "TdsConnection.h"
#import "QueryResult.h"
      
#import "CreateTableScript.h"

void testCreateTableSctipt(){
	TdsConnection *connection = [TdsConnection alloc];	
	[connection initWithServer: @"mssql.mobilnet.hr" user: @"sa" password: @""];
	[connection login];  
	
	NSLog(@"\n%@", [CreateTableScript scriptWithConnection: connection database: @"pubs" table: @"authors"]);
	NSLog(@"\n%@", [CreateTableScript scriptWithConnection: connection database: @"SuperSport" table: @"SlipBetts"]);
	NSLog(@"\n%@", [CreateTableScript scriptWithConnection: connection database: @"SuperSport" table: @"Slips"]);
	                   
	[connection release];
}

void testQueryResultsRetainCount(){
	TdsConnection *connection = [TdsConnection alloc];	
	[connection initWithServer: @"mssql.mobilnet.hr" user: @"sa" password: @""];
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

int main (int argc, const char * argv[]) {	
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];  
	NSLog(@"uses garbage collection %d", [NSGarbageCollector defaultCollector] != nil);
	
	// testQueryResultsRetainCount();
	testCreateTableSctipt();

	NSLog(@"shell test finished...");
	[pool drain];
	return 0;
} 
                                  

