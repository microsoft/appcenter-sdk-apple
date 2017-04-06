#import <Foundation/Foundation.h>

@protocol MSSerializableObject <NSCoding>

/**
 * Serialize this object to a dictionary.
 *
 * @return A dictionary representing this object.
 */
- (NSMutableDictionary *)serializeToDictionary;

@end
