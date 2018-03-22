#import <Foundation/Foundation.h>
#import "MSTransmissionTarget.h"

@interface MSTransmissionTarget ()

/**
 * The transmission token corresponding to this transmission target.
 */
@property(nonatomic) NSString *transmissionToken;

- (instancetype)initWithTransmissionToken:(NSString *)transmissionToken;

@end
