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

void testMaxColumnLength(){
	TdsConnection *connection = [TdsConnection alloc];	
	[connection initWithServer: @"mssql.mobilnet.hr" user: @"sa" password: @""];
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

int main (int argc, const char * argv[]) {	
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];  
	NSLog(@"uses garbage collection %d", [NSGarbageCollector defaultCollector] != nil);
	
	// testQueryResultsRetainCount();
	//testCreateTableSctipt();
	testMaxColumnLength();
	
	NSLog(@"shell test finished...");
	[pool drain];
	return 0;
} 
                                  

