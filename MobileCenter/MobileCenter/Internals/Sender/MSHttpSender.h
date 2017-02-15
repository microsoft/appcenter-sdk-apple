#import "MSSender.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MSHttpSender : NSObject <MSSender>

/**
 *	Send Url.
 */
@property(nonatomic, strong, readonly) NSURL *sendURL;

/**
 *	Request header parameters.
 */
@property(nonatomic, strong) NSDictionary *httpHeaders;

/**
 *  Pending http calls.
 */
@property(atomic, strong) NSMutableDictionary<NSString *, MSSenderCall *> *pendingCalls;

/**
 *  Send data to backend
 * @param data A data instance that will be transformed request body.
 * @param callId A unique ID that identify a request.
 * @param handler Completion handler
 */
- (void)sendAsync:(NSObject *)data callId:(NSString *)callId completionHandler:(MSSendAsyncCompletionHandler)handler;

@end

NS_ASSUME_NONNULL_END
