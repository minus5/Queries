#import <Cocoa/Cocoa.h>
#import <Foundation/Foundation.h>

#import "ColumnMetadata.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>
#include <errno.h>
#include <unistd.h>
#include <libgen.h>

#define _WINDEF_
//#define WIN32
#define TDS50 0

#include <sqlfront.h>	
#include <sybdb.h>

@interface QueryExec : NSObject {

	NSString *_serverName;
	NSString *_databaseName;
	NSString *_userName;
	NSString *_password;
	NSMutableArray *messages;
	NSMutableArray *results;
	int currentResult;
	
	DBPROCESS *dbproc;

}

-(id) initWithCredentials: (NSString*) serverName 
						 databaseName: (NSString*) databaseName 
								 userName: (NSString*) userName 
								 password: (NSString*) password;

-(void) login;

-(BOOL) execute: (NSString*) query;
-(void) executeQuery: (NSString*) query;
-(NSArray*) readResultMetadata: (struct COL**) pcolumns;
-(NSArray*) readResultData: (struct COL*) columns;
-(void) freeResultBuffers: (struct COL*) columns;
-(void) readResultMessages;
-(void) readResults;


-(void) logMessage: (NSString*) message;
-(BOOL) hasMessages;
-(NSArray*) getMessages;

-(NSString*) connectionName;

-(int) resultsCount;
-(void) nextResult;
-(void) previousResult;
-(BOOL) hasResults;
-(BOOL) hasNextResults;
-(BOOL) hasPreviosResults;
-(NSArray*) columns;
-(NSArray*) rows;
-(int) rowsCount;
-(NSString*) rowValue: (int) rowIndex: (int) columnIndex;

@end
