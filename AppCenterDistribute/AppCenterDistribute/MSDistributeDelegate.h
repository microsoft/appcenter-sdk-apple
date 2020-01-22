// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSReleaseDetails.h"

@class MSDistribute;

@protocol MSDistributeDelegate <NSObject>

typedef NS_ENUM(NSInteger, MSUpdateAction) {

  /**
   * Action to trigger update.
   */
  MSUpdateActionUpdate,

  /**
   * Action to postpone update.
   */
  MSUpdateActionPostpone
};

typedef NS_ENUM(NSInteger, MSUpdateTrack) {

  /**
   * Releases from the public group that don't require authentication.
   */
  MSUpdateTrackPublic = 1,

  /**
   * Releases from private groups that require authentication, also contain public releases.
   */
  MSUpdateTrackPrivate = 2
};

@optional

/**
 * Callback method that will be called whenever a new release is available for update.
 *
 * @param distribute The instance of MSDistribute.
 * @param details Release details for the update.
 *
 * @return Return YES if you want to take update control by overriding default update dialog, NO otherwise.
 *
 * @see [MSDistribute notifyUpdateAction:]
 */
- (BOOL)distribute:(MSDistribute *)distribute releaseAvailableWithDetails:(MSReleaseDetails *)details;

@end
