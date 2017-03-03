#import <Foundation/Foundation.h>

/*
 * Return the application's main bundle.
 *
 * @return Instance of NSBUndle, the Application's main bundle.
 */
NSBundle *MSUpdatesBundle(void);

/*
 * Return a localized string for the given token.
 *
 * @param The string token that will be looked for in the .strings file.
 *
 * @return A localized string.
 *
 * @discussion This needs the MobileCenterDistributeResources.bundle to be added to the project. If the bundle is missing,
 * the method will return the provided stringToken. In case nil or an empty string is passed to the method, it will
 * return an empty string. If the .strings file does not contain a string for the token, it will return the token.
 */
NSString *MSUpdatesLocalizedString(NSString *stringToken);
