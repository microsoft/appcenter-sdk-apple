#import <Foundation/Foundation.h>

typedef void (^MSSendAsyncCompletionHandler)(NSString *callId, NSUInteger statusCode, NSData *data, NSError *error);

static short const kMSMaxCharactersDisplayedForAppSecret = 8;
static NSString *const kMSHidingStringForAppSecret = @"*";

@interface MSIngestionUtil : NSObject

/**
 * Indicate if the http response is recoverable.
 *
 * @param statusCode Http status code.
 *
 * @return is recoverable.
 */
+ (BOOL)isRecoverableError:(NSInteger)statusCode;

/**
 * Get http status code from response.
 *
 * @param response http response.
 *
 * @return status code.
 */
+ (NSInteger)getStatusCode:(NSURLResponse *)response;

/**
 * Indicate if error is due to no internet connection.
 *
 * @param error http error.
 *
 * @return YES if it is a no network connection error, NO otherwise.
 */
+ (BOOL)isNoInternetConnectionError:(NSError *)error;

/**
 * Indicate if error is because a secure connection could not be established, e.g. when using a public network that * is open but requires
 * accepting terms and conditions, and the user hasn't done that, yet.
 *
 * @param error http error.
 *
 * @return YES if it is an SSL connection error, NO otherwise.
 */
+ (BOOL)isSSLConnectionError:(NSError *)error;

/**
 * Indicate if error is due to cancelation of the request.
 *
 * @param error http error.
 *
 * @return is request canceled.
 */
+ (BOOL)isRequestCanceledError:(NSError *)error;

/**
 * Hide a secret replacing the first N characters by a hiding character.
 *
 * @param secret the secret string.
 *
 * @return secret by hiding some characters.
 */
+ (NSString *)hideSecret:(NSString *)secret;

@end
