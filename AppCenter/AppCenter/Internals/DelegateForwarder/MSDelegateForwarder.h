#import <Foundation/Foundation.h>

@interface MSDelegateForwarder : NSObject

/**
 * Enable/Disable Application forwarding.
 */
@property(nonatomic) BOOL enabled;

/**
 * Returns the singleton instance of MSAppDelegateForwarder.
 */
+ (instancetype)sharedInstance;

@end
