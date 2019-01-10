#import <Foundation/Foundation.h>

@interface MSOrderedDictionary : NSMutableDictionary

- (instancetype)initWithCapacity:(NSUInteger)numItems;

- (void)setObject:(id)anObject forKey:(id<NSCopying>)aKey;

- (BOOL)isEqualToDictionary:(NSDictionary *)otherDictionary;

@end
