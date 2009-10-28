#import "ColumnMetadata.h"

@implementation ColumnMetadata

@synthesize name, size, type, index;

-(id) initWithName: (NSString*) n size: (int) s type: (int) t index: (int) i
{
	self = [super init];
	
	if(self){
		name = [[NSString alloc] initWithString: n];
		size = s;
		type = t;		
		index = i;
	}
	
	return self;
}

@end
