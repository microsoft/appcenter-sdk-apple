#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol MSAuthTokenContextDelegate;

@interface MSAuthTokenContext : NSObject

/**
 * Auth token.
 */
@property(nonatomic, nullable) NSString *authToken;

/**
 * Get singleton instance.
 */
+ (instancetype)sharedInstance;

/**
 * Add delegate.
 *
 * @param delegate Delegate.
 */
- (void)addDelegate:(id<MSAuthTokenContextDelegate>)delegate;

@end

NS_ASSUME_NONNULL_END
