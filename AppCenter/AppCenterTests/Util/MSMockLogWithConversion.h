#import <Foundation/Foundation.h>

#import "MSLog.h"
#import "MSLogConversion.h"

@protocol MSMockLogWithConversion <MSLog, MSLogConversion, NSObject>
@end
