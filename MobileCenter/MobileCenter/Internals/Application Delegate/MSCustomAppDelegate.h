#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class MSAppDelegateForwarder;

/**
 * Custom delegate matching `UIApplicationDelegate`.
 *
 * @discussion Delegates here are using swizzling. Any delegate that can be registered through the notification center
 * should not be registered through swizzling.
 */
@protocol MSCustomAppDelegate <NSObject>

@optional

/**
 * Asks the delegate to open a resource specified by a URL, and provides a dictionary of launch options.
 *
 * @param app The singleton app object.
 * @param url The URL resource to open. This resource can be a network resource or a file.
 * @param sourceApplication The bundle ID of the app that is requesting your app to open the URL (url).
 * @param annotation A Property list supplied by the source app to communicate information to the receiving app.
 * @param returnedValue Value returned by the original delegate implementation.
 *
 * @return `YES` if the delegate successfully handled the request or `NO` if the attempt to open the URL resource
 * failed.
 */
- (BOOL)application:(UIApplication *)app
              openURL:(NSURL *)url
    sourceApplication:(nullable NSString *)sourceApplication
           annotation:(id)annotation
        returnedValue:(BOOL)returnedValue;

/**
 * Asks the delegate to open a resource specified by a URL, and provides a dictionary of launch options.
 *
 * @param app The singleton app object.
 * @param url The URL resource to open. This resource can be a network resource or a file.
 * @param options A dictionary of URL handling options.
 * For information about the possible keys in this dictionary and how to handle them, @see
 * UIApplicationOpenURLOptionsKey. By default, the value of this parameter is an empty dictionary.
 * @param returnedValue Value returned by the original delegate implementation.
 *
 * @return `YES` if the delegate successfully handled the request or `NO` if the attempt to open the URL resource
 * failed.
 */
- (BOOL)application:(UIApplication *)app
            openURL:(NSURL *)url
            options:(NSDictionary<UIApplicationOpenURLOptionsKey, id> *)options
      returnedValue:(BOOL)returnedValue;

@end

NS_ASSUME_NONNULL_END
