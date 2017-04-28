@interface MSMobileCenter ()

/**
 * Method to reset the singleton when running unit tests only. So calling sharedInstance returns a fresh instance.
 */
+ (void)resetSharedInstance;

// TODO: Move to MSMobileCenter.h when backend is ready.
/**
 * Set the custom properties.
 *
 * @param customProperties Custom properties object.
 */
+ (void)setCustomProperties:(MSCustomProperties *)customProperties;
@end
