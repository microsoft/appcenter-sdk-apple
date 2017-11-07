#import <Foundation/Foundation.h>

#import "MSSender.h"

NS_ASSUME_NONNULL_BEGIN

@interface MSHttpSender : NSObject <MSSender>

/**
 * Base URL (schema + authority + port only) used to communicate with the server.
 */
@property(nonatomic, copy) NSString *baseURL;

/**
 * API URL path used to identify an API from the server.
 */
@property(nonatomic, copy) NSString *apiPath;

/**
 *	Send Url.
 */
@property(nonatomic) NSURL *sendURL;

/**
 *	Request header parameters.
 */
@property(nonatomic) NSDictionary *httpHeaders;

/**
 *  Pending http calls.
 */
@property NSMutableDictionary<NSString *, MSSenderCall *> *pendingCalls;

/**
 *  Send data to backend
 * @param data A data instance that will be transformed into a request body.
 * @param callId A unique ID that identifies a request.
 * @param handler The completion handler that will be executed.
 */
- (void)sendAsync:(NSObject *)data callId:(NSString *)callId completionHandler:(MSSendAsyncCompletionHandler)handler;

@end

NS_ASSUME_NONNULL_END
