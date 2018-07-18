#import "MSException.h"
#import "MSStackFrame.h"
#import "MSThread.h"

static NSString *const kMSThreadId = @"id";
static NSString *const kMSName = @"name";
static NSString *const kMSStackFrames = @"frames";
static NSString *const kMSException = @"exception";

@implementation MSThread

// Initializes a new instance of the class.
- (instancetype)init {
  if ((self = [super init])) {
    _frames = [NSMutableArray array];
  }
  return self;
}

- (NSMutableDictionary *)serializeToDictionary {
  NSMutableDictionary *dict = [NSMutableDictionary new];

  if (self.threadId) {
    dict[kMSThreadId] = self.threadId;
  }
  if (self.name) {
    dict[kMSName] = self.name;
  }

  if (self.frames) {
    NSMutableArray *framesArray = [NSMutableArray array];
    for (MSStackFrame *frame in self.frames) {
      [framesArray addObject:[frame serializeToDictionary]];
    }
    dict[kMSStackFrames] = framesArray;
  }

  if (self.exception) {
    dict[kMSException] = [self.exception serializeToDictionary];
  }

  return dict;
}

- (BOOL)isValid {
  return self.threadId && [self.frames count] > 0;
}

- (BOOL)isEqual:(id)object {
  if (![(NSObject *)object isKindOfClass:[MSThread class]]) {
    return NO;
  }
  MSThread *thread = (MSThread *)object;
  return ((!self.threadId && !thread.threadId) || [self.threadId isEqual:thread.threadId]) &&
         ((!self.name && !thread.name) || [self.name isEqualToString:thread.name]) &&
         ((!self.frames && !thread.frames) || [self.frames isEqualToArray:thread.frames]) &&
         ((!self.exception && !thread.exception) || [self.exception isEqual:thread.exception]);
}

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super init];
  if (self) {
    _threadId = [coder decodeObjectForKey:kMSThreadId];
    _name = [coder decodeObjectForKey:kMSName];
    _frames = [coder decodeObjectForKey:kMSStackFrames];
    _exception = [coder decodeObjectForKey:kMSException];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [coder encodeObject:self.threadId forKey:kMSThreadId];
  [coder encodeObject:self.name forKey:kMSName];
  [coder encodeObject:self.frames forKey:kMSStackFrames];
  [coder encodeObject:self.exception forKey:kMSException];
}

@end
