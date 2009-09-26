#import <Cocoa/Cocoa.h>
#import <Foundation/Foundation.h>

@interface ColumnMetadata : NSObject {
	
	NSString *name;
	int size;
	int type;
	int index;
}

-(id) initWithName: (NSString*) n 
							size: (int) s 
							type: (int) t
						 index: (int) i;


@property (copy, nonatomic) NSString *name;
@property int size, type, index;

@end





