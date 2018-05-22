#import <Foundation/Foundation.h>

@interface MSSdkExtension : NSObject

/**
 * The SDK version.
 */
@property(nonatomic, copy) NSString *ver;

/**
 * ID incremented for each SDK initialization.
 */
@property(nonatomic, copy) NSString *epoch;

/**
 * ID incremented for each event.
 */
@property(nonatomic) int64_t seq;

/**
 * ID created on first-time SDK initialization. It may serves as the device.localId.
 */
@property(nonatomic, copy) NSString *installId;

@end
