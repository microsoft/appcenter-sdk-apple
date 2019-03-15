#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol MSSerialization

/**
 * Create a dictionary from the object.
 *
 * @return Dictionary representing the object.
 */
@required
- (NSDictionary *)serializeToDictionary;

/**
 * Construct an object from a dictionary.
 *
 * @param dictionary of object
 *
 * @return An instance of the object
 */
@required
- (instancetype)initFromDictionary:(NSDictionary *)dictionary;

@end

NS_ASSUME_NONNULL_END
