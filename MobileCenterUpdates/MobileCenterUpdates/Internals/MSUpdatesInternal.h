#import <Foundation/Foundation.h>
#import "MSReleaseDetails.h"
#import "MSSender.h"
#import "MSServiceInternal.h"
#import "MSUpdates.h"

@interface MSUpdates () <MSServiceInternal>

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

/**
 * Update workflow to make a dicision of update based on release details.
 */
- (void)handleUpdate:(MSReleaseDetails *)details;

/**
 * Show a dialog to ask a user to confirm update for a new release.
 */
- (void)showConfirmationAlert:(MSReleaseDetails *)details;

/**
 * Check whether release details contain a newer version of release than current version.
 */
- (BOOL)isNewerVersion:(MSReleaseDetails *)details;

@end
