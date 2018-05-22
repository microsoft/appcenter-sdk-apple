#import <Foundation/Foundation.h>

@interface MSProtocolExtension : NSObject

/**
 * The device's manufacturer.
 */
@property(nonatomic, copy) NSString *devMake;

/**
 * The device's model.
 */
@property(nonatomic, copy) NSString *devModel;

@end
