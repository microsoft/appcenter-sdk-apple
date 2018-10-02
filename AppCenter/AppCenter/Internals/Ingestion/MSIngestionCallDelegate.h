#import <Foundation/Foundation.h>

#import "MSConstants+Internal.h"

@class MSIngestionCall;

@protocol MSIngestionCallDelegate <NSObject>

/**
 * Send call.
 *
 * @param call Call object.
 */
- (void)sendCallAsync:(MSIngestionCall *)call;

/**
 * Call completed callback.
 *
 * @param call Call object.
 * @param result Enum indicating the result of the call.
 */
- (void)call:(MSIngestionCall *)call completedWithResult:(MSIngestionCallResult)result;

@end
