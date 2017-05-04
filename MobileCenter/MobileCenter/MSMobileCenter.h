#import <Foundation/Foundation.h>
#import "MSConstants.h"

/**
 * Use forward declarations instead of import to minimize the amount of code seen by the compiler and linker.
 * It avoids potential problems that may come with importing files that import still other files.
 */
@class MSWrapperSdk;
@class MSCustomProperties;

@interface MSMobileCenter : NSObject

/**
 * Returns the singleton instance of MSMobileCenter.
 */
+ (instancetype)sharedInstance;

/**
 * Configure the SDK.
 *
 * @discussion This may be called only once per application process lifetime.
 * @param appSecret A unique and secret key used to identify the application.
 */
+ (void)configureWithAppSecret:(NSString *)appSecret;

/**
 * Configure the SDK with an application secret and an array of services to start.
 *
 * @discussion This may be called only once per application process lifetime.
 * @param appSecret A unique and secret key used to identify the application.
 * @param services  Array of services to start.
 */
+ (void)start:(NSString *)appSecret withServices:(NSArray<Class> *)services;

/**
 * Start a service.
 * @discussion This may be called only once per service per application process lifetime.
 * @param service  A service to start.
 */
+ (void)startService:(Class)service;

/**
 * Check whether the SDK has already been configured or not.
 *
 * @return YES if configured, NO otherwise.
 */
+ (BOOL)isConfigured;

/**
 * Change the base URL (schema + authority + port only) used to communicate with the backend.
 *
 * @param logUrl Base URL to use for backend communication.
 */
+ (void)setLogUrl:(NSString *)logUrl;

/**
 * Enable or disable the SDK as a whole. In addition to MobileCenter resources, it will also enable or
 * disable all registered services.
 *
 * @param isEnabled YES to enable, NO to disable.
 * @see isEnabled
 */
+ (void)setEnabled:(BOOL)isEnabled;

/**
 * Check whether the SDK is enabled or not as a whole.
 *
 * @return YES if enabled, NO otherwise.
 * @see setEnabled:
 */
+ (BOOL)isEnabled;

/**
 * Get log level.
 *
 * @return Log level.
 */
+ (MSLogLevel)logLevel;

/**
 * Set log level.
 *
 * @param logLevel The log level.
 */
+ (void)setLogLevel:(MSLogLevel)logLevel;

/**
 * Set log level handler.
 *
 * @param logHandler Handler.
 */
+ (void)setLogHandler:(MSLogHandler)logHandler;

/**
 * Set wrapper SDK information to use when building device properties. This is intended in case you are building a SDK
 * that uses the Mobile Center SDK under the hood, e.g. our Xamarin SDK or ReactNative SDk.
 *
 * @param wrapperSdk Wrapper SDK information.
 */
+ (void)setWrapperSdk:(MSWrapperSdk *)wrapperSdk;

/**
 * Get unique installation identifier.
 *
 * @return Unique installation identifier.
 */
+ (NSUUID *)installId;

/**
 * Detect if a debugger is attached to the app process. This is only invoked once on app startup and can not detect
 * if the debugger is being attached during runtime!
 *
 * @return BOOL if the debugger is attached.
 */
+ (BOOL)isDebuggerAttached;

@end
