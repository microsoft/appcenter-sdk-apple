#import "MSAppleErrorLog.h"
#import "MSBinary.h"
#import "MSException.h"
#import "MSThread.h"

static NSString *const kMSTypeError = @"appleError";
static NSString *const kMSPrimaryArchitectureId = @"primaryArchitectureId";
static NSString *const kMSArchitectureVariantId = @"architectureVariantId";
static NSString *const kMSApplicationPath = @"applicationPath";
static NSString *const kMSOsExceptionType = @"osExceptionType";
static NSString *const kMSOsExceptionCode = @"osExceptionCode";
static NSString *const kMSOsExceptionAddress = @"osExceptionAddress";
static NSString *const kMSExceptionType = @"exceptionType";
static NSString *const kMSExceptionReason = @"exceptionReason";
static NSString *const kMSSelectorRegisterValue = @"selectorRegisterValue";
static NSString *const kMSThreads = @"threads";
static NSString *const kMSBinaries = @"binaries";
static NSString *const kMSRegisters = @"registers";
static NSString *const kMSException = @"exception";

@implementation MSAppleErrorLog

- (instancetype)init {
  if ((self = [super init])) {
    self.type = kMSTypeError;
  }
  return self;
}

- (NSMutableDictionary *)serializeToDictionary {
  NSMutableDictionary *dict = [super serializeToDictionary];

  if (self.primaryArchitectureId) {
    dict[kMSPrimaryArchitectureId] = self.primaryArchitectureId;
  }
  if (self.architectureVariantId) {
    dict[kMSArchitectureVariantId] = self.architectureVariantId;
  }
  if (self.applicationPath) {
    dict[kMSApplicationPath] = self.applicationPath;
  }
  if (self.osExceptionType) {
    dict[kMSOsExceptionType] = self.osExceptionType;
  }
  if (self.osExceptionCode) {
    dict[kMSOsExceptionCode] = self.osExceptionCode;
  }
  if (self.osExceptionAddress) {
    dict[kMSOsExceptionAddress] = self.osExceptionAddress;
  }
  if (self.exceptionType) {
    dict[kMSExceptionType] = self.exceptionType;
  }
  if (self.exceptionReason) {
    dict[kMSExceptionReason] = self.exceptionReason;
  }
  if (self.selectorRegisterValue) {
    dict[kMSSelectorRegisterValue] = self.selectorRegisterValue;
  }
  if (self.threads) {
    NSMutableArray *threadsArray = [NSMutableArray array];
    for (MSThread *thread in self.threads) {
      [threadsArray addObject:[thread serializeToDictionary]];
    }
    dict[kMSThreads] = threadsArray;
  }
  if (self.binaries) {
    NSMutableArray *binariesArray = [NSMutableArray array];
    for (MSBinary *binary in self.binaries) {
      [binariesArray addObject:[binary serializeToDictionary]];
    }
    dict[kMSBinaries] = binariesArray;
  }
  if (self.registers) {
    dict[kMSRegisters] = self.registers;
  }
  if (self.exception) {
    dict[kMSException] = [self.exception serializeToDictionary];
  }

  return dict;
}

- (BOOL)isValid {
  return [super isValid] && self.primaryArchitectureId && self.applicationPath && self.osExceptionType && self.osExceptionCode &&
         self.osExceptionAddress;
}

- (BOOL)isEqual:(id)object {
  if (![(NSObject *)object isKindOfClass:[MSAppleErrorLog class]] || ![super isEqual:object]) {
    return NO;
  }
  MSAppleErrorLog *errorLog = (MSAppleErrorLog *)object;
  return ((!self.primaryArchitectureId && !errorLog.primaryArchitectureId) ||
          [self.primaryArchitectureId isEqual:errorLog.primaryArchitectureId]) &&
         ((!self.architectureVariantId && !errorLog.architectureVariantId) ||
          [self.architectureVariantId isEqual:errorLog.architectureVariantId]) &&
         ((!self.applicationPath && !errorLog.applicationPath) || [self.applicationPath isEqualToString:errorLog.applicationPath]) &&
         ((!self.osExceptionType && !errorLog.osExceptionType) || [self.osExceptionType isEqualToString:errorLog.osExceptionType]) &&
         ((!self.osExceptionCode && !errorLog.osExceptionCode) || [self.osExceptionCode isEqualToString:errorLog.osExceptionCode]) &&
         ((!self.osExceptionAddress && !errorLog.osExceptionAddress) ||
          [self.osExceptionAddress isEqualToString:errorLog.osExceptionAddress]) &&
         ((!self.exceptionType && !errorLog.exceptionType) || [self.exceptionType isEqualToString:errorLog.exceptionType]) &&
         ((!self.exceptionReason && !errorLog.exceptionReason) || [self.exceptionReason isEqualToString:errorLog.exceptionReason]) &&
         ((!self.selectorRegisterValue && !errorLog.selectorRegisterValue) ||
          ([self.selectorRegisterValue isEqualToString:errorLog.selectorRegisterValue])) &&
         ((!self.threads && !errorLog.threads) || [self.threads isEqualToArray:errorLog.threads]) &&
         ((!self.binaries && !errorLog.binaries) || [self.binaries isEqualToArray:errorLog.binaries]) &&
         ((!self.registers && !errorLog.registers) || [self.registers isEqualToDictionary:errorLog.registers]) &&
         ((!self.exception && !errorLog.exception) || [self.exception isEqual:errorLog.exception]);
}

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super initWithCoder:coder];
  if (self) {
    _primaryArchitectureId = [coder decodeObjectForKey:kMSPrimaryArchitectureId];
    _architectureVariantId = [coder decodeObjectForKey:kMSArchitectureVariantId];
    _applicationPath = [coder decodeObjectForKey:kMSApplicationPath];
    _osExceptionType = [coder decodeObjectForKey:kMSOsExceptionType];
    _osExceptionCode = [coder decodeObjectForKey:kMSOsExceptionCode];
    _osExceptionAddress = [coder decodeObjectForKey:kMSOsExceptionAddress];
    _exceptionType = [coder decodeObjectForKey:kMSExceptionType];
    _exceptionReason = [coder decodeObjectForKey:kMSExceptionReason];
    _selectorRegisterValue = [coder decodeObjectForKey:kMSSelectorRegisterValue];
    _threads = [coder decodeObjectForKey:kMSThreads];
    _binaries = [coder decodeObjectForKey:kMSBinaries];
    _registers = [coder decodeObjectForKey:kMSRegisters];
    _exception = [coder decodeObjectForKey:kMSException];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [super encodeWithCoder:coder];
  [coder encodeObject:self.primaryArchitectureId forKey:kMSPrimaryArchitectureId];
  [coder encodeObject:self.architectureVariantId forKey:kMSArchitectureVariantId];
  [coder encodeObject:self.applicationPath forKey:kMSApplicationPath];
  [coder encodeObject:self.osExceptionType forKey:kMSOsExceptionType];
  [coder encodeObject:self.osExceptionCode forKey:kMSOsExceptionCode];
  [coder encodeObject:self.osExceptionAddress forKey:kMSOsExceptionAddress];
  [coder encodeObject:self.exceptionType forKey:kMSExceptionType];
  [coder encodeObject:self.exceptionReason forKey:kMSExceptionReason];
  [coder encodeObject:self.selectorRegisterValue forKey:kMSSelectorRegisterValue];
  [coder encodeObject:self.threads forKey:kMSThreads];
  [coder encodeObject:self.binaries forKey:kMSBinaries];
  [coder encodeObject:self.registers forKey:kMSRegisters];
  [coder encodeObject:self.exception forKey:kMSException];
}

@end
