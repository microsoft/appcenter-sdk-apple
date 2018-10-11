#import <Foundation/Foundation.h>

#import "MSEventProperties.h"

@class MSTypedProperty;

NS_ASSUME_NONNULL_BEGIN

/**
 * Typed event properties.
 */
@interface MSEventProperties () <NSCoding>

/**
 * String and date properties.
 */
@property (nonatomic) NSMutableDictionary<NSString *, MSTypedProperty *> *properties;

/**
 * Creates an instance of EventProperties with a string-string properties dictionary.
 *
 * @param properties A dictionary of properties.
 *
 * @return An instance of EventProperties.
 */
- (instancetype)initWithDictionary:(NSDictionary<NSString *, NSString *> *)properties;

/**
 * Serialize this object to an array.
 *
 * @return An array representing this object.
 */
- (NSMutableArray *)serializeToArray;

/**
 * Indicates whether there are any properties in the collection.
 *
 * @return `YES` if there are no properties in the collection, `NO` otherwise.
 */
- (BOOL)isEmpty;

@end

NS_ASSUME_NONNULL_END
