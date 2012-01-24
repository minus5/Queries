#import <Cocoa/Cocoa.h>
#import <Foundation/Foundation.h>

@interface ColumnMetadata : NSObject {
	
	NSString *name;
	int size;
	int type;
	int index;
	int length;
}

-(id) initWithName: (NSString*) n 
							size: (int) s 
							type: (int) t
						 index: (int) i;

- (void) updateMaxLength: (int) l;
//- (NSString*) formatString;

@property (copy, nonatomic) NSString *name;
@property int size, type, index, length;

@end





