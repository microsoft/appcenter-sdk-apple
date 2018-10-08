#import <Foundation/Foundation.h>
#import "MSSerializableObject.h"

static NSString *const kMSTypedPropertyValue = @"value";

@interface MSTypedProperty : NSObject <MSSerializableObject>

/**
 * Property type (NSString, double, long long, BOOL, or NSDate).
 */
@property(nonatomic, copy) NSString *type;

/**
 * Property name.
 */
@property(nonatomic, copy) NSString *name;

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
