#import <SenTestingKit/SenTestingKit.h>

#import "ColumnMetadata.h"
#import "TdsConnection.h"
#import "QueryResult.h"

@interface TdsConnectionTest : SenTestCase {
	
}

@end


@implementation TdsConnectionTest

-(void) testShouldPass{
	STAssertTrue(YES, @"This sohould be true");
}

-(TdsConnection*) connection{
	TdsConnection *c = [TdsConnection alloc];	
	[c initWithServer: @"mssql.mobilnet.hr" user: @"sa" password: @""];	
	[c login];	
	return c;
}

-(void) testQueryOnPublishersHasBeenFailing{	
	QueryResult* result = [[self connection] execute: @"select * from pubs.dbo.publishers"];
	STAssertTrue([result hasResults], nil);
	STAssertEquals([result resultsCount], 1, nil);
}

/*
-(void) testOneResult{
	QueryExec *queryExec = [self connectToPubsDatabase];
	[queryExec execute:@"select * from authors order by au_id"];
	 
	STAssertEquals([queryExec resultsCount], 1, @"One result should be returned");
	STAssertEquals([queryExec hasResults], YES, nil);
	STAssertEquals([queryExec hasNextResults], NO, nil);
	STAssertEquals([queryExec hasPreviosResults], NO, nil);
	STAssertEquals([queryExec rowsCount], 23, nil);
	STAssertEquals((int)[[queryExec columns] count], 9, nil);
	STAssertEquals((int)[[queryExec rows] count], 23, nil);
	
	STAssertEqualObjects([[[queryExec columns] objectAtIndex:0] name], @"au_id", nil);
	STAssertEqualObjects([[[queryExec columns] objectAtIndex:1] name], @"au_lname", nil);
	STAssertEqualObjects([[[queryExec columns] objectAtIndex:2] name], @"au_fname", nil);
	
	STAssertEqualObjects([queryExec	rowValue:0 :1], @"White", nil);
	STAssertEqualObjects([queryExec	rowValue:0 :2], @"Johnson", nil);	
}

-(void) testManyResults{
	QueryExec *queryExec = [self connectToPubsDatabase];
	[queryExec execute:@"sp_help authors"];
	
	STAssertEquals([queryExec resultsCount], 9, nil);
	STAssertEquals([queryExec hasResults], YES, nil);
	STAssertEquals([queryExec hasNextResults], YES, nil);
	STAssertEquals([queryExec hasPreviosResults], NO, nil);
	STAssertEquals([queryExec rowsCount], 1, nil);
	
	STAssertEqualObjects([queryExec	rowValue:0 :1], @"dbo", nil);
	STAssertEqualObjects([queryExec	rowValue:0 :2], @"user table", nil);
	
	[queryExec nextResult];
	STAssertEquals([queryExec hasNextResults], YES, nil);
	STAssertEquals([queryExec hasPreviosResults], YES, nil);
	STAssertEquals([queryExec rowsCount], 9, nil);
	[queryExec nextResult];
	STAssertEquals([queryExec rowsCount], 1, nil);
	[queryExec nextResult];
	STAssertEquals([queryExec rowsCount], 1, nil);
	[queryExec nextResult];
	STAssertEquals([queryExec rowsCount], 1, nil);
	[queryExec nextResult];
	STAssertEquals([queryExec rowsCount], 2, nil);
	[queryExec nextResult];
	STAssertEquals([queryExec rowsCount], 4, nil);
	[queryExec nextResult];
	STAssertEquals([queryExec rowsCount], 1, nil);
	[queryExec nextResult];
	STAssertEquals([queryExec hasNextResults], NO, nil);
	STAssertEquals([queryExec hasPreviosResults], YES, nil);
	STAssertEquals([queryExec rowsCount], 0, nil);			
}
*/
@end
