#import "MSAbstractDocument.h"
#import "MSAppCenterInternal.h"
#import "MSDataStoreInternal.h"

@implementation MSAbstractDocument

- (instancetype)initFromDictionary:(NSDictionary *)__unused dictionary {
  
  // This method needs to be implemented by the super class.
  @try {
    [self doesNotRecognizeSelector:_cmd];
    return nil;
  }
  @catch (NSException *exception) {
    MSLogError([MSDataStore logTag], @"Missing implementation of initFromDictionary: method, error:%@", [exception reason]);
  }
  return nil;
}

- (NSDictionary *)serializeToDictionary {
  
  // This method needs to be implemented by the super class.
  @try {
    [self doesNotRecognizeSelector:_cmd];
  }
  @catch (NSException *exception) {
    MSLogError([MSDataStore logTag], @"Missing implementation of serializeToDictionary method, error:%@", [exception reason]);
  }
  return nil;
}

@end
