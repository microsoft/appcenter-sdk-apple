#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Typed event properties.
 */
@interface MSEventProperties () <MSSerializableObject>

/**
 * String and date properties.
 */
@property (nonatomic) NSMutableDictionary<NSString *, NSObject *> *properties;

/**
 * Creates an instance of EventProperties with a string-string properties dictionary.
 *
 * @param properties A dictionary of properties.
 * @return An instance of EventProperties.
 */
- (instancetype)initWithDictionary:(NSDictionary<NSString *, NSString *> *)properties;

@end

NS_ASSUME_NONNULL_END