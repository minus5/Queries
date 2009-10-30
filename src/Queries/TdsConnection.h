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

@interface TdsConnection : NSObject {

	NSString *_serverName;
	NSString *_databaseName;
	NSString *_userName;
	NSString *_password;     
	
	NSString *fileName;     
	
	NSMutableArray *messages;
	NSMutableArray *results;
	
	int currentResultIndex;
	
	NSString *_queryText;
	NSRange _selection;
	BOOL isEdited;
	BOOL isProcessing;
	 
	DBPROCESS *dbproc;
}
                    
@property BOOL isEdited;
@property BOOL isProcessing;
@property (copy) NSString *queryText; 
@property NSRange selection; 
@property (readonly) int currentResultIndex;
@property (readonly) NSArray *messages;
@property (readonly) NSArray *results;     
@property (copy) NSString *fileName;

-(id) initWithCredentials: (NSString*) serverName 
						 databaseName: (NSString*) databaseName 
								 userName: (NSString*) userName 
								 password: (NSString*) password;

-(void) login;
-(void) logout;

-(BOOL) execute: (NSString*) query;
-(BOOL) execute: (NSString*) query withDefaultDatabase: (NSString*) database;
// -(NSString*) queryFromQueryTextAndSelection;
// -(BOOL) execute;
	
-(void) executeQuery: (NSString*) query;
-(NSArray*) readResultMetadata: (struct COL**) pcolumns;
-(NSArray*) readResultData: (struct COL*) columns;
-(void) freeResultBuffers: (struct COL*) columns;
-(void) readResultMessages;
-(void) readResults;

-(void) logMessage: (NSString*) message;

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
-(NSString*) resultAsString;

-(NSString*) currentDatabase;

@end
