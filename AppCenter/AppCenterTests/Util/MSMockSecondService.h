#import "MSServiceAbstract.h"
#import "MSServiceInternal.h"

@interface MSMockSecondService : MSServiceAbstract <MSServiceInternal>

@property BOOL started;

+ (void)resetSharedInstance;

@end
