#import <Foundation/Foundation.h>

#import "MSHttpIngestion.h"

@protocol MSIngestionDelegate;

@interface MSHttpIngestion ()

@property(nonatomic) NSURLSession *session;

/**
 * The maximum number of connections for the session. The one collector endpoint only allows for two connections while the app center
 * endpoint doesn't impose a limit, using the iOS default value of 4 connections for this.
 */
@property(nonatomic, readonly) NSInteger maxNumberOfConnections;

/**
 * Retry intervals used by calls in case of recoverable errors.
 */
@property(nonatomic) NSArray *callsRetryIntervals;

/**
 * Hash table containing all the delegates as weak references.
 */
@property NSHashTable<id<MSIngestionDelegate>> *delegates;

/**
 * A boolean value set to YES if the ingestion is enabled or NO otherwise.
 * Enable/disable does resume/pause the ingestion as needed under the hood.
 */
@property(nonatomic) BOOL enabled;

/**
 * Initialize the Ingestion.
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
 * Initialize the Ingestion.
 *
 * @param baseUrl Base url.
 * @param apiPath Base API path.
 * @param headers Http headers.
 * @param queryStrings An array of query strings.
 * @param reachability Network reachability helper.
 * @param retryIntervals An array for retry intervals in second.
 * @param maxNumberOfConnections The maximum number of connections per host.
 */
- (id)initWithBaseUrl:(NSString *)baseUrl
                   apiPath:(NSString *)apiPath
                   headers:(NSDictionary *)headers
              queryStrings:(NSDictionary *)queryStrings
              reachability:(MS_Reachability *)reachability
            retryIntervals:(NSArray *)retryIntervals
    maxNumberOfConnections:(NSInteger)maxNumberOfConnections;

/**
 * Create a request based on data. Must override this method in sub classes.
 *
 * @param data A data instance that will be transformed to request body.
 *
 * @return A URL request.
 */
- (NSURLRequest *)createRequest:(NSObject *)data;

/**
 * Convert key/value pairs for headers to a string.
 *
 * @param headers A dictionary that contains header as key/value pair.
 *
 * @return A string that contains headers.
 */
- (NSString *)prettyPrintHeaders:(NSDictionary<NSString *, NSString *> *)headers;

/**
 * Hide a part of sensitive value for log.
 *
 * @param key A header key.
 * @param value  A header value.
 *
 * @return An obfuscated value.
 */
- (NSString *)obfuscateHeaderValue:(NSString *)value forKey:(NSString *)key;

@end
