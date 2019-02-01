#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MSIdentityAuthority : NSObject

/**
 * The type of the authority
 */
@property(nonatomic, copy) NSString *type;

/**
 * The flag that indicates whether the authority is default or not.
 */
@property(nonatomic) BOOL defaultAuthority;

/**
 * The authority URL of user flow.
 */
@property(nonatomic, copy) NSURL *authorityUrl;

/**
 * Initialize an object from dictionary.
 *
 * @param dictionary A dictionary that contains the key/value pairs for an authority.
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
