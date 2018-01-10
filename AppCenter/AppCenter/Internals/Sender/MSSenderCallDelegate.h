#import <Foundation/Foundation.h>

#import "MSConstants+Internal.h"

@class MSSenderCall;

@protocol MSSenderCallDelegate <NSObject>

/**
 *  Send call.
 *
 *  @param call Call object.
 */
- (void)sendCallAsync:(MSSenderCall *)call;

/**
 *  Call completed callback.
 *
 *  @param call Call object.
 *  @param result Enum indicating the result of the call.
 */
- (void)call:(MSSenderCall *)call completedWithResult:(MSSenderCallResult)result;

@end
