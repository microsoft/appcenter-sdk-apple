#import <Foundation/Foundation.h>

#import "MSDistribute.h"
#import "MSDistributeIngestion.h"
#import "MSIngestionProtocol.h"
#import "MSReleaseDetailsPrivate.h"
#import "MSServiceInternal.h"

#define APP_CENTER_DISTRIBUTE_BUNDLE @"AppCenterDistributeResources.bundle"

NS_ASSUME_NONNULL_BEGIN

/**
 * The keychain key for update token.
 */
static NSString *const kMSUpdateTokenKey = @"MSUpdateToken";

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
 * An ingestion instance that is used to send a request for new release to the backend.
 */
@property(nonatomic, nullable) MSDistributeIngestion *ingestion;

@end

NS_ASSUME_NONNULL_END
