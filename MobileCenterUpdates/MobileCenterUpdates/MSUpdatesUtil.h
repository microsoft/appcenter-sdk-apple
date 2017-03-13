#import "MSReleaseDetails.h"
#import <Foundation/Foundation.h>

/**
 * Return the application's main bundle.
 *
 * @return Instance of NSBUndle, the Application's main bundle.
 */
NSBundle *MSUpdatesBundle(void);

/**
 * Return a localized string for the given token.
 *
 * @param stringToken The string token that will be looked for in the .strings file.
 *
 * @return A localized string.
 *
 * @discussion This needs the MobileCenterUpdatesResources.bundle to be added to the project. If the bundle is missing,
 * the method will return the provided stringToken. In case nil or an empty string is passed to the method, it will
 * return an empty string. If the .strings file does not contain a string for the token, it will return the token.
 */
NSString *MSUpdatesLocalizedString(NSString *stringToken);

/**
 * Check compliancy of given version against semantic versioning format.
 *
 * @param version A version to check against semantic versioning format.
 *
 * @return `YES` if the given version is compatible with semantic versioning format.
 */
BOOL MSisSemVerFormat(NSString *version);

/**
 * Compare current release for this hosting app with given release.
 *
 * @param release Release to compare with current app release.
 *
 * @return The comparison result determining releases precedence.
 */
NSComparisonResult MSCompareCurrentReleaseWithRelease(MSReleaseDetails *release);
