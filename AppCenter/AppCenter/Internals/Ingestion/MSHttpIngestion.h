#import <Foundation/Foundation.h>

#import "MSIngestionProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface MSHttpIngestion : NSObject <MSIngestionProtocol>

/**
 * Base URL (schema + authority + port only) used to communicate with the server.
 */
@property(nonatomic, copy) NSString *baseURL;

/**
 * API URL path used to identify an API from the server.
 */
@property(nonatomic, copy) NSString *apiPath;

/**
 * Send Url.
 */
@property(nonatomic) NSURL *sendURL;

/**
 * Request header parameters.
 */
@property(nonatomic) NSDictionary *httpHeaders;

/**
 * Pending http calls.
 */
@property NSMutableDictionary<NSString *, MSIngestionCall *> *pendingCalls;

/**
 * Send data to backend
 *
 * @param data A data instance that will be transformed request body.
 * @param callId A unique ID that identify a request.
 * @param handler Completion handler
 */
- (void)sendAsync:(NSObject *)data callId:(NSString *)callId completionHandler:(MSSendAsyncCompletionHandler)handler;

@end

NS_ASSUME_NONNULL_END
