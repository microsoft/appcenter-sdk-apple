

#import "MSCSSequenceGenerator.h"

@interface MSCSSequence ()
@property(nonatomic) NSUInteger sequence;
@end

@implementation MSCSSequence

- (NSUInteger)nextValue {
  NSUInteger result;
  @synchronized(self) {
    ++self.sequence;
    result = self.sequence;
  }
  return result;
}

@end

@implementation MSCSSequenceGenerator

static NSMutableDictionary *sequences;
static NSMutableDictionary *tokens;

+ (MSCSSequence *)sequenceForTenant:(NSString *)tenant {
  MSCSSequence *sequence = nil;
  if (tenant && tenant.length) {
    @synchronized([self class]) {
      if (!sequences) {
        sequences = [NSMutableDictionary new];
      } else {
        NSString *key = tenant.lowercaseString;
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
