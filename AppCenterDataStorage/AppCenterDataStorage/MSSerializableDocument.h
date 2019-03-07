#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol MSSerializableDocument

/**
 * Create a dictionary from the object.
 *
 * @return Dictionary representing the object.
 */
- (NSDictionary *)serializeToDictionary;

/**
 * Track an event.
 *
 * @param eventName  Event name. Cannot be `nil` or empty.
 *
 * @discussion Validation rules apply depending on the configured secret.
 *
 * For App Center, the name cannot be longer than 256 and is truncated otherwise.
 *
 * For One Collector, the name needs to match the `[a-zA-Z0-9]((\.(?!(\.|$)))|[_a-zA-Z0-9]){3,99}` regular expression.
 */

/**
 * Construct an object from a dictionary.
 *
 * @param dictionary of object
 *
 * @return An instance of the object
 */
- (instancetype)initFromDictionary:(NSDictionary *)dictionary;

@end

NS_ASSUME_NONNULL_END
