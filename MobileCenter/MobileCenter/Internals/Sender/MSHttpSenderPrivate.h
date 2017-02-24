#import <Foundation/Foundation.h>

@protocol MSSenderDelegate;

@interface MSHttpSender ()

@property(nonatomic, strong) NSURLSession *session;

/**
 * Retry intervals used by calls in case of recoverable errors.
 */
@property(nonatomic, strong) NSArray *callsRetryIntervals;

/**
 * Hash table containing all the delegates as weak references.
 */
@property(atomic, strong) NSHashTable<id<MSSenderDelegate>> *delegates;

/**
 * A boolean value set to YES if the sender is enabled or NO otherwise.
 * Enable/disable does resume/suspend the sender as needed under the hood.
 */
@property(nonatomic) BOOL enabled;

/**
 * Initialize the Sender.
 *
 * @param baseUrl Base url.
 * @param apiPath Base API path.
 * @param headers Http headers.
 * @param queryStrings An array of query strings.
 * @param reachability Network reachability helper.
 * @param retryIntervals An array for retry intervals in second.
 */
- (id)initWithBaseUrl:(NSString *)baseUrl
              apiPath:(NSString *)apiPath
              headers:(NSDictionary *)headers
         queryStrings:(NSDictionary *)queryStrings
         reachability:(MS_Reachability *)reachability
       retryIntervals:(NSArray *)retryIntervals;

/**
 * Create a request based on data. Must override this method in sub classes.
 * @param data A data instance that will be transformed to request body.
 * @return A URL request.
 */
- (NSURLRequest *)createRequest:(NSObject *)data;

/**
 * Convert key/value pairs for headers to a string.
 * @param headers A dictionary that contains header as key/value pair.
 * @return A string that contains headers.
 */
- (NSString *)prettyPrintHeaders:(NSDictionary<NSString *, NSString *> *)headers;

@end
