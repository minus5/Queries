#import "CreateTableScript.h"

@implementation CreateTableScript

@synthesize script;

- (void) createTable{	 
	[script appendFormat: @"CREATE TABLE %@ (\n", tableName];
}

- (void) columns{
	NSArray *columnsResult = [result resultAtIndex: 1];
	int columnsCount = [columnsResult count];
	for(int i = 0; i < columnsCount; i++){
		[self column: [columnsResult objectAtIndex:i]];
		if (i < columnsCount - 1)
			[script appendFormat: @",\n"];
  }      
	[self primaryKey];
	[self foreignKeys];
	[script appendFormat: @"\n) ON [%@]\n", [result valueAtResult: 4 row:0 column:0]];	
}

- (void) column:(NSArray*) columnData{             
	NSString *columnName = [columnData objectAtIndex: 0];
	NSString *dataType = [columnData objectAtIndex: 1];
	NSString *length = [columnData objectAtIndex: 3];
	NSString *prec = [columnData objectAtIndex: 4];
	NSString *scale = [columnData objectAtIndex: 5]; 
	BOOL notNull = [[columnData objectAtIndex: 6] isEqualToString: @"no"];
	
	[script appendFormat: @"\t[%@] %@", columnName, dataType];

	if ([dataType isEqualToString:@"char"] || [dataType isEqualToString:@"varchar"] ||
		[dataType isEqualToString:@"binary"] || [dataType isEqualToString:@"varbinary"])
		[script appendFormat: @"(%@)", length];                                           
	 
	if ([dataType isEqualToString:@"nchar"] || [dataType isEqualToString:@"nvarchar"]){
		[script appendFormat: @"(%@)", [[NSNumber numberWithInteger: [length integerValue] / 2] stringValue]];  
	}

	if ([dataType isEqualToString:@"numeric"] || [dataType isEqualToString:@"decimal"])
		[script appendFormat: @"(%@, %@)", prec, scale];		
		
	if (notNull)
		[script appendFormat: @" NOT NULL"];
 
	[self identity: columnName];
	[self rowguid: columnName];
	[self columnDefault: columnName];  
	[self columnCheck: columnName];
}                                             

- (void) rowguid:(NSString*) columnName{
	NSString *rowguidColumnName = [result valueAtResult: 3 row: 0 column: 0];
	if (!rowguidColumnName)
		return;
	if ([columnName isEqualToString: rowguidColumnName]){
		[script appendFormat: @" ROWGUIDCOL"];
	}        	
} 

- (void) identity:(NSString*) columnName{
	NSString *identityColumnName = [result valueAtResult: 2 row: 0 column: 0];
	if (!identityColumnName)
		return;
	if ([columnName isEqualToString: identityColumnName]){
		[script appendFormat: @" IDENTITY(%@, %@)",                            
			[result valueAtResult: 2 row: 0 column: 1],
			[result valueAtResult: 2 row: 0 column: 2]];
	}        	
}        

- (void) columnDefault:(NSString*) columnName{
	NSArray *defaultRows = [self constraintResults];
	if (defaultRows){
		for(id row in defaultRows){                                                                 
			NSString *constraintName = [row objectAtIndex: 0];
			if ([[NSString stringWithFormat: @"DEFAULT on column %@", columnName] isEqualToString: constraintName]){
				[script appendFormat: @" DEFAULT %@", [row objectAtIndex: 6]];
			}
		}
	}
}  

- (void) columnCheck:(NSString*) columnName{
	NSArray *constraints = [self constraintResults];
	if (constraints){
		for(id constraint in constraints){                                                                 
			NSString *constraintName = [constraint objectAtIndex: 0];
			if ([[NSString stringWithFormat: @"CHECK on column %@", columnName] isEqualToString: constraintName]){
				[script appendFormat: @" CHECK %@", [constraint objectAtIndex: 6]];
			}
		}
	}
}

- (void) primaryKey{
	NSArray *constraints = [self constraintResults];
	if (constraints){
		for(id constraint in constraints){  			
			NSString *constraintType = [constraint objectAtIndex: 0];
			if ([constraintType rangeOfString: @"PRIMARY KEY"].length > 0){
				[script appendFormat:@",\n\tCONSTRAINT [%@] PRIMARY KEY %@ (%@)",
					[constraint objectAtIndex: 1],
					([constraintType rangeOfString: @"clustered"].length > 0 ? @"CLUSTERED" : @""),
					[constraint objectAtIndex: 6]
					];
			}
		}
	}
} 

- (void) foreignKeys{
	NSArray *constraints = [self constraintResults];
	if (constraints){                    
		for(int i = 0; i < [constraints count]; i++)
		{                                           
			NSArray *constraint = [constraints objectAtIndex: i];
			NSString *constraintType = [constraint objectAtIndex: 0];
			if ([constraintType rangeOfString: @"FOREIGN KEY"].length > 0){
				[script appendFormat:@",\n\tCONSTRAINT [%@] FOREIGN KEY (%@) %@",
					[constraint objectAtIndex: 1],					
					[constraint objectAtIndex: 6],
					[[constraints objectAtIndex: ++i] objectAtIndex: 6]
					];
			}
		}
	}
}      

- (void) indexes{
	NSArray *indexes = [self indexResults];
	if (indexes){
		for(id index in indexes){  			
			NSString *indexDescription = [index objectAtIndex: 1];
			if ([indexDescription rangeOfString: @"primary key"].length == 0){ 				
				NSRange range = [indexDescription rangeOfString: @"located on "];
								
				[script appendFormat:@"\nCREATE %@%@INDEX [%@] ON %@(%@) ON [%@]",					
					([indexDescription rangeOfString: @"unique"].length > 0 ? @"UNIQUE " : @""),
					([indexDescription rangeOfString: @"nonclustered"].length == 0 ? @"CLUSTERED " : @""),
					[index objectAtIndex: 0],
					tableName,                    
					[index objectAtIndex: 2],
					[indexDescription substringFromIndex: range.location + range.length]
					];
			}
		}
	}
}   

- (NSArray*) indexResults{      
	return [result resultWithFirstColumnNamed: @"index_name"];
}  

- (NSArray*) constraintResults{                            
	return [result resultWithFirstColumnNamed: @"constraint_type"];
}

+ (NSString*) scriptWithConnection: (TdsConnection*) connection  database:(NSString*) database table: (NSString*) table{
	CreateTableScript *scripter = [[[CreateTableScript alloc] initWithConnection: connection database: database table: table] autorelease];
	return [scripter script];
} 
                                 
- (id) initWithConnection: (TdsConnection*) connection  database:(NSString*) database table: (NSString*) table{
	if (self = [super init]){
		result = [connection execute: [NSString stringWithFormat: @"use %@\nexec sp_help '%@'", database, table]];		
		
		NSArray *nameParts = [table componentsSeparatedByString: @"."];
		tableName = [NSString stringWithFormat: @"[%@].[%@]", 
			[nameParts objectAtIndex: 0],		
			[nameParts objectAtIndex: 1]];
				
		script = [[NSMutableString string] retain];    
		
		[self createTable];  
		[self columns];					                                                           
		[self indexes];
	}
	return self;
} 
                                                                
- (void) dealloc{       	
	[script release];
	[super dealloc];
}

@end
											