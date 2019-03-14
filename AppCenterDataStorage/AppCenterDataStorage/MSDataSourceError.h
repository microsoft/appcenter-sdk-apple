#import <Foundation/Foundation.h>

@interface MSDataSourceError : NSObject

/**
 * Document Error.
 */
@property(nonatomic, strong, readonly) NSError *error;

/**
 * Create an instance with error object.
 *
 * @param error An error object.
 *
 * @return A new `MSDataSourceError` instance.
 */
- (instancetype)initWithError:(NSError *)error;

@end
