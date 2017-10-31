#import <Foundation/Foundation.h>
#import "MSDistribute.h"
#import "MSDistributeSender.h"
#import "MSReleaseDetailsPrivate.h"
#import "MSSender.h"
#import "MSServiceInternal.h"

#define APP_CENTER_DISTRIBUTE_BUNDLE @"AppCenterDistributeResources.bundle"

NS_ASSUME_NONNULL_BEGIN

@interface MSDistribute () <MSServiceInternal>

/**
 * An install URL that is used when the SDK needs to acquire update token.
 */
@property(nonatomic, copy) NSString *installUrl;

/**
 * An API url that is used to get release details from backend.
 */
@property(nonatomic, copy) NSString *apiUrl;

/**
 * A sender instance that is used to send a request for new release to the backend.
 */
@property(nonatomic, nullable) MSDistributeSender *sender;

@end

NS_ASSUME_NONNULL_END

