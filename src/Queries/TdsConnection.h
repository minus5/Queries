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
#include "QueryResult.h"

@class QueryResult;

@interface TdsConnection : NSObject {

	NSString *_serverName;
	NSString *_userName;
	NSString *_password;     
		
	QueryResult *queryResult;
	  
	BOOL isProcessing; 	 
	DBPROCESS *dbproc;
}

@property BOOL isProcessing;

-(id) initWithCredentials: (NSString*) serverName 
								 userName: (NSString*) userName 
								 password: (NSString*) password;
								
- (DBPROCESS*) dbproc;

-(void) login;
-(void) logout;

-(QueryResult*) execute: (NSString*) query;
-(QueryResult*) execute: (NSString*) query withDefaultDatabase: (NSString*) database;

-(void) executeQuery: (NSString*) query;
-(NSArray*) readResultMetadata: (struct COL**) pcolumns;
-(NSArray*) readResultData: (struct COL*) columns;
-(void) freeResultBuffers: (struct COL*) columns;
-(void) readResultMessages;
-(void) readResults;

-(void) logMessage: (NSString*) message;

-(NSString*) connectionName;
  
-(NSString*) currentDatabase;

- (TdsConnection*) clone;

@end
