#import <Foundation/Foundation.h>

//NS_ASSUME_NONNULL_BEGIN
@interface MSOrderedDictionary : NSMutableDictionary {
  NSMutableDictionary *dictionary;
}

@property(nonatomic) NSMutableArray *order;

- (instancetype)initWithCapacity:(NSUInteger)numItems;

- (void)setObject:(id)anObject forKey:(id<NSCopying>)aKey;

@end
//NS_ASSUME_NONNULL_END
