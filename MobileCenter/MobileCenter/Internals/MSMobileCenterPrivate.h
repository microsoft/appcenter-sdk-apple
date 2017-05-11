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

/**
 * Configure the SDK.
 *
 * @discussion This may be called only once per application process lifetime.
 * @param appSecret A unique and secret key used to identify the application.
 */
// FIXME: Rename to configureWithAppSecret
- (BOOL)configure:(NSString *)appSecret;

@end
