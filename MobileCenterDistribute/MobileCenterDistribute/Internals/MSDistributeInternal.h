#import <Foundation/Foundation.h>
#import "MSDistribute.h"
#import "MSReleaseDetails.h"
#import "MSSender.h"
#import "MSServiceInternal.h"

#define MOBILE_CENTER_UPDATES_BUNDLE @"MobileCenterDistributeResources.bundle"

@interface MSDistribute () <MSServiceInternal>

/**
 * An install URL that is used when the SDK needs to acquire update token.
 */
@property(nonatomic, copy) NSString *installUrl;

/**
 * An API url that is used to get update details from backend.
 */
@property(nonatomic, copy) NSString *apiUrl;

@end
