#import "MSCoreLog.h"

static NSString *const kMSStartService = @"start_service";
static NSString *const kMSServices = @"services";

@implementation MSCoreLog

@synthesize type = _type;
@synthesize services = _services;

- (instancetype)init {
  self = [super init];
  if( self ) {
    self.type = kMSStartService;
  }
  return self;
}

#pragma mark - MSSerializableObject

- (NSMutableDictionary *)serializeToDictionary {
  NSMutableDictionary *dict = [super serializeToDictionary];
  if( dict ) {
    if( self.services ) {
      dict[kMSServices] = self.services;
    }
  }
  return dict;
}

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super initWithCoder:coder];
  if( self ) {
    self.type = [coder decodeObjectForKey:kMSStartService];
    self.services = [coder decodeObjectForKey:kMSServices];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [super encodeWithCoder:coder];
  [coder encodeObject:self.type forKey:kMSStartService];
  [coder encodeObject:self.services forKey:kMSServices];
}

@end
