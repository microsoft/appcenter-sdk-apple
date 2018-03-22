#import <Foundation/Foundation.h>
#import "MSTransmissionTarget.h"

@interface MSTransmissionTarget ()

/**
 * The transmission target token corresponding to this transmission target.
 */
@property(nonatomic) NSString *transmissionTargetToken;

- (instancetype)initWithTransmissionTargetToken:(NSString *)token;

@end
