#import <Foundation/Foundation.h>

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
 * Creates a copy of `self` that is valid for App Center.
 *
 * @return A copy of `self` that is valid for App Center.
 */
- (instancetype)createValidCopyForAppCenter;

/**
 * Creates a copy of `self` that is valid for One Collector.
 *
 * @return A copy of `self` that is valid for One Collector.
 */
- (instancetype)createValidCopyForOneCollector;

@end

NS_ASSUME_NONNULL_END
