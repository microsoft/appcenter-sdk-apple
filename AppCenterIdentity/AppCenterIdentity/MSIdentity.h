#import "MSServiceAbstract.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * App Center Identity service.
 */
@interface MSIdentity : MSServiceAbstract

+ (void)handleUrlResponse:(NSURL *)url;

@end

NS_ASSUME_NONNULL_END
