#import <Foundation/Foundation.h>

@interface MSOrderedDictionary : NSMutableDictionary {
  NSMutableDictionary *dictionary;
}

@property(nonatomic) NSMutableArray *order;

- (instancetype)initWithCapacity:(NSUInteger)numItems;

- (void)setObject:(id)anObject forKey:(id<NSCopying>)aKey;

@end
