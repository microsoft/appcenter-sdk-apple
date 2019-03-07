#import <Foundation/Foundation.h>
#import "MSConstants.h"

@class MSTokenResult;

@interface MSTokensResponse : NSObject

/**
 * List of tokens.
 */
@property(nonatomic, readonly) NSArray<MSTokenResult *> *tokens;

/**
 * Initialize the Token response object.
 *
 * @param tokens List of tokens.
 *
 * @return An token response instance.
 */
- (instancetype)initWithTokens:(NSArray<MSTokenResult *> *)tokens;

/**
 * Initialize the Token response object with dictionary of tokens.
 *
 * @param tokens Dictionary of tokens
 *
 * @return An token response instance.
 */
- (instancetype)initWithDictionary:(NSDictionary *)tokens;

@end
