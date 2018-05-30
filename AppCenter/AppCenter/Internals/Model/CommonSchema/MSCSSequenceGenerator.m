

#import "MSCSSequenceGenerator.h"

@interface MSCSSequence ()
@property(nonatomic) NSUInteger sequence;
@end

@implementation MSCSSequence

- (NSUInteger)nextValue {
  @synchronized(self) {
    return ++self.sequence;
  }
}

@end

@implementation MSCSSequenceGenerator

static NSMutableDictionary *sequences;
static NSMutableDictionary *tokens;

+ (MSCSSequence *)sequenceForTargetToken:(NSString *)token {
  MSCSSequence *sequence = nil;
  if (token && token.length) {
    @synchronized([self class]) {
      if (!sequences) {
        sequences = [NSMutableDictionary new];
      } else {
        NSString *key = token.lowercaseString;
        if (!sequences[key]) {
          sequence = [MSCSSequence new];
          sequences[key] = sequence;
        }
      }
    }
  }
  return sequence;
}

+ (void)reset {
  @synchronized([self class]) {
    [sequences removeAllObjects];
    sequences = nil;

    [tokens removeAllObjects];
    tokens = nil;
  }
}

@end
