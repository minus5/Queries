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
#import "RegexKitLite.h"

@class QueryResult;

@interface TdsConnection : NSObject {

	NSString *server;
	NSString *user;
	NSString *password;     
	NSString *connectionDefaults;
		
	QueryResult *queryResult;
	  
	BOOL isProcessing; 	  
	BOOL cancelQuery;   
	DBPROCESS *dbproc;
}

@property BOOL isProcessing;

-(id) initWithServer: (NSString*) s user: (NSString*) u password: (NSString*) p connectionDefaults: (NSString*) d;
								
- (DBPROCESS*) dbproc;

-(void) login;
-(void) logout;

-(QueryResult*) execute: (NSString*) query;
-(QueryResult*) execute: (NSString*) query withDefaultDatabase: (NSString*) database; 
-(QueryResult*) execute: (NSString*) query withDefaultDatabase: (NSString*) database logOutOnException: (bool)logOutOnException;
-(void) executeQueries: (NSString*) query;
- (BOOL) executeInBackground: (NSString*) query withDatabase: (NSString*) database returnToObject: (id) receiver withSelector: (SEL) selector;
-(void) executeInBackground: (NSDictionary*) arguments;

-(BOOL) executeQuery: (NSString*) query;
-(NSArray*) readResultMetadata: (struct COL**) pcolumns;
-(NSArray*) readResultData: (struct COL*) columns  withColumnNames: (NSArray*) columnNames;

-(void) freeResultBuffers: (struct COL*) columns;
-(void) readResultMessages;
-(void) readResults;
                
+ (void) logMessage: (NSString*) message forProcess: (DBPROCESS*) dbproc error: (BOOL)isError;
-(void) logMessage: (NSString*) message error: (BOOL) isError;

-(NSString*) connectionName;
  
-(NSString*) currentDatabase;

-(TdsConnection*) clone;

-(void) setCancelQuery;
-(void) applyConnectionDefaults;

@end
