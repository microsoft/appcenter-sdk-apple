#import <Foundation/Foundation.h>

#import "MSIdentityAuthority.h"

NS_ASSUME_NONNULL_BEGIN

@interface MSIdentityConfig : NSObject

@property(nonatomic, copy) NSString *identityScope;

@property(nonatomic, copy) NSString *clientId;

@property(nonatomic, copy) NSString *redirectUri;

@property(nonatomic, copy) NSArray<MSIdentityAuthority *> *authorities;

/**
 * Initialize an object from dictionary.
 *
 * @param dictionary A dictionary that contains key/value pairs.
 *
 * @return  A new instance.
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
