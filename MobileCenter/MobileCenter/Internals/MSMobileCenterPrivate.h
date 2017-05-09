#import "MSMobileCenter.h"

@interface MSMobileCenter ()

/**
 * Method to reset the singleton when running unit tests only. So calling sharedInstance returns a fresh instance.
 */
+ (void)resetSharedInstance;

/**
 * Set the custom properties.
 *
 * @param customProperties Custom properties object.
 */
// TODO: Move to MSMobileCenter.h when backend is ready.
+ (void)setCustomProperties:(MSCustomProperties *)customProperties;

@end
