#import <Foundation/Foundation.h>
#import "MSReleaseDetails.h"
#import "MSSender.h"
#import "MSServiceInternal.h"
#import "MSUpdates.h"

#define MOBILE_CENTER_UPDATES_BUNDLE @"MobileCenterUpdatesResources.bundle"

@interface MSUpdates ()

/**
 * An install URL that is used when the SDK needs to acquire update token.
 */
@property(nonatomic, copy) NSString *installUrl;

/**
 * An API url that is used to get update details from backend.
 */
@property(nonatomic, copy) NSString *apiUrl;

/**
 * A sender instance that is used to send update request to the backend.
 */
@property(nonatomic) id<MSSender> sender;

@end
