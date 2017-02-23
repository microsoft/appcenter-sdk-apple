#import <Foundation/Foundation.h>

@class MSDistributionGroup;

NS_ASSUME_NONNULL_BEGIN

/**
 * Details of an uploaded release.
 */
@interface MSReleaseDetails : NSObject

/**
 * ID identifying this unique release.
 */
@property(nonatomic, copy) NSNumber *id;

/**
 * OBSOLETE. Will be removed in next version. The availability concept is now replaced with distributed.
 * Any 'available' associated with the default distribution group of an app.
 * enum:
 *   available
 *   unavailable
 */
@property(nonatomic, copy) NSString *status;

/**
 * The app's name
 */
@property(nonatomic, copy) NSString *appName;

/**
 * The release's version
 * For iOS: CFBundleVersion from info.plist
 * For Android: android:versionCode from AndroidManifest.xml
 */
@property(nonatomic, copy) NSString *version;

/**
 * The release's short version.
 * For iOS: CFBundleShortVersionString from info.plist
 * For Android: android:versionName from AndroidManifest.xml
 */
@property(nonatomic, copy) NSString *shortVersion;

/**
 * The release's release notes.
 */
@property(nonatomic, copy) NSString *releaseNotes;

/**
 * The release's provisioning profile name.
 */
@property(nonatomic, copy) NSString *provisioningProfileName;

/**
 * The release's size in bytes.
 */
@property(nonatomic, copy) NSNumber *size;

/**
 * The release's minimum required operating system.
 */
@property(nonatomic, copy) NSString *minOs;

/**
 * MD5 checksum of the release binary.
 */
@property(nonatomic, copy) NSString *fingerprint;

/**
 * UTC time in ISO 8601 format of the uploaded time.
 */
@property(nonatomic, copy) NSDate *uploadedAt;

/**
 * The URL that hosts the binary for this release.
 */
@property(nonatomic, copy) NSURL *downloadUrl;

/**
 * A URL to the app's icon.
 */
@property(nonatomic, copy) NSURL *appIconUrl;

/**
 * The href required to install a release on a mobile device.
 * On iOS devices will be prefixed with 'itms-services://?action=download-manifest&url='
 */
@property(nonatomic, copy) NSURL *installUrl;

/**
 * A list of distribution groups that are associated with this release.
 */
@property(nonatomic, copy) NSArray<MSDistributionGroup *> *distributionGroups;

/**
 * Initialize an object from dictionary.
 *
 * @param dictionary A dictionary that contains key/value pairs.
 *
 * @return  A new instance.
 */
- (instancetype)initWithDictionary:(NSMutableDictionary *)dictionary;

/**
 * Checks if the values are valid.
 *
 * return YES if it is valid, otherwise NO.
 */
- (BOOL)isValid;

@end

NS_ASSUME_NONNULL_END
