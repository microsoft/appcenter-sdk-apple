#import <Foundation/Foundation.h>

#import "MSIdentityAuthority.h"

NS_ASSUME_NONNULL_BEGIN

@interface MSIdentityConfig : NSObject

/**
 * The identity scope to be used for user authentication.
 */
@property(nonatomic, copy) NSString *identityScope;

/**
 * The client ID (aka application ID) of Azure AD B2C application.
 */
@property(nonatomic, copy) NSString *clientId;

/**
 * The redirect URI to get back to an application after authentication.
 */
@property(nonatomic, copy) NSString *redirectUri;

/**
 * The authorities that contain URLs for user flows.
 */
@property(nonatomic, copy) NSArray<MSIdentityAuthority *> *authorities;

/**
 * Initialize an object from dictionary.
 *
 * @param dictionary A dictionary that contains key/value pairs.
 *
 * @return A new instance.
 */
- (instancetype)initWithDictionary:(NSDictionary *)dictionary;

/**
 * Checks if the object's values are valid.
 *
 * @return YES, if the object is valid.
 */
- (BOOL)isValid;

@end

NS_ASSUME_NONNULL_END
