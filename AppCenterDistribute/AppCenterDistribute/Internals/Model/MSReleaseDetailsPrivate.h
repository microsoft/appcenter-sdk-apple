#import <Foundation/Foundation.h>

#import "MSReleaseDetails.h"

@class MSDistributionGroup;

/**
 * Details of an uploaded release.
 */
@interface MSReleaseDetails ()

/**
 * OBSOLETE. Will be removed in next version. The availability concept is now replaced with distributed. Any 'available' associated with the
 * default distribution group of an app. enum: available unavailable
 */
@property(nonatomic, copy) NSString *status;

/**
 * The app's name
 */
@property(nonatomic, copy) NSString *appName;

/**
 * The release's provisioning profile name.
 */
@property(nonatomic, copy) NSString *provisioningProfileName;

/**
 * The release's size in bytes.
 */
@property(nonatomic) NSNumber *size;

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
@property(nonatomic) NSDate *uploadedAt;

/**
 * The URL that hosts the binary for this release.
 */
@property(nonatomic) NSURL *downloadUrl;

/**
 * The URL to the app's icon.
 */
@property(nonatomic) NSURL *appIconUrl;

/**
 * The href required to install a release on a mobile device.
 * On iOS devices will be prefixed with
 * 'itms-services://?action=download-manifest&url='
 */
@property(nonatomic) NSURL *installUrl;

/**
 * Distribution group identifier.
 */
@property(nonatomic) NSString *distributionGroupId;

/**
 * A list of distribution groups that are associated with this release.
 */
@property(nonatomic) NSArray<MSDistributionGroup *> *distributionGroups;

/**
 * A list of package hashes associated with this release. There is one hash
 * (UUID) per architecture.
 */
@property(nonatomic) NSArray<NSString *> *packageHashes;

/**
 * Initialize an object from dictionary.
 *
 * @param dictionary A dictionary that contains key/value pairs.
 *
 * @return  A new instance.
 */
- (instancetype)initWithDictionary:(NSDictionary *)dictionary;

/**
 * Serialize this object to a dictionary.
 *
 * @return A dictionary representing this object.
 */
- (NSDictionary *)serializeToDictionary;

/**
 * Checks if the values are valid.
 *
 * @return YES if it is valid, otherwise NO.
 */
- (BOOL)isValid;

@end
