#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol MSOriginalAppDelegate <NSObject>

@optional

/**
 * Asks the delegate to open a resource specified by a URL, and provides a dictionary of launch options.
 *
 * @param app The singleton app object.
 * @param url The URL resource to open. This resource can be a network resource or a file.
 * @param sourceApplication The bundle ID of the app that is requesting your app to open the URL (url).
 * @param annotation A Property list supplied by the source app to communicate information to the receiving app.
 *
 * @return `YES` if the delegate successfully handled the request or `NO` if the attempt to open the URL resource
 * failed.
 */
- (BOOL)ms_original_application:(UIApplication *)app
                        openURL:(NSURL *)url
              sourceApplication:(nullable NSString *)sourceApplication
                     annotation:(id)annotation;

/**
 * Asks the delegate to open a resource specified by a URL, and provides a dictionary of launch options.
 *
 * @param app The singleton app object.
 * @param url The URL resource to open. This resource can be a network resource or a file.
 * @param options A dictionary of URL handling options.
 * For information about the possible keys in this dictionary and how to handle them, @see
 * UIApplicationOpenURLOptionsKey. By default, the value of this parameter is an empty dictionary.
 *
 * @return `YES` if the delegate successfully handled the request or `NO` if the attempt to open the URL resource
 * failed.
 */
- (BOOL)ms_original_application:(UIApplication *)app
                        openURL:(NSURL *)url
                        options:(NSDictionary<UIApplicationOpenURLOptionsKey, id> *)options;

@end

NS_ASSUME_NONNULL_END
