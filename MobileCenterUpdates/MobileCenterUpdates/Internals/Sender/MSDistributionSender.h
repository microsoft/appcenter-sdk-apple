#import <Foundation/Foundation.h>
#import "MSHttpSender.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * The header name for update token.
 */
static NSString *const kMSHeaderUpdateApiToken = @"x-api-token";

@interface MSDistributionSender : MSHttpSender

// FIXME: Temporary fix to avoid merge conflict.
@property(nonatomic) NSString *appSecret;

@end

NS_ASSUME_NONNULL_END
