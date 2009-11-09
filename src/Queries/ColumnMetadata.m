#import "ColumnMetadata.h"

@implementation ColumnMetadata

@synthesize name, size, type, index, length;

-(id) initWithName: (NSString*) n size: (int) s type: (int) t index: (int) i
{
	self = [super init];
	
	if(self){
		name = [[NSString alloc] initWithString: n];
		size = s;
		type = t;		
		index = i;
		length = [name length];
	}
	
	return self;
}

- (void) updateMaxLength: (int) l{
	if (l > length)
		length = l;
}                        

// - (NSString*) formatString{
// 	return [NSString stringWithFormat: @"%%-%ds", [self length] + 2];
// }

@end
