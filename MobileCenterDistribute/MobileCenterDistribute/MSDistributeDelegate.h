#import "MSReleaseDetails.h"

@class MSDistribute;

@protocol MSDistributeDelegate <NSObject>

typedef NS_ENUM(NSInteger, MSUserUpdateAction) {

  /**
   * Action to trigger update.
   */
  MSUserUpdateActionUpdate,

  /**
   * Action to postpone update.
   */
  MSUserUpdateActionPostpone,

  /**
   * Action to ignore current update.
   */
  MSUserUpdateActionIgnore
};

@optional

/**
 * Callback method that will be called whenever a new release is available for update.
 *
 * @param releaseDetails Release details for the update.
 *
 * @return Return YES and if you want to take update control by overriding default update dialog, NO otherwise.
 *
 * @seealso [MSDistribute notifyUserUpdateAction:]
 */
- (BOOL)onNewUpdateAvailable:(MSReleaseDetails *)releaseDetails;

@end
