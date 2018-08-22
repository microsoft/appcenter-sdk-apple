#import "MSLog.h"
#import "MSLogConversion.h"
#import <Foundation/Foundation.h>

@protocol MSMockLogWithConversion <MSLog, MSLogConversion, NSObject>
@end
