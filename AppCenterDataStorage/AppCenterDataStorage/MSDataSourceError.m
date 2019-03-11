#import "MSDataSourceError.h"

@implementation MSDataSourceError

@synthesize error= _error;

- (instancetype)initWithError:(NSError *)error {
  if ((self = [super init])) {
    _error = error;
  }
  return self;
}

@end
