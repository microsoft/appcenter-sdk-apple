/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "AVAThreadFrame.h"

static NSString *const kAVAAddress = @"address";
static NSString *const kAVASymbol = @"symbol";
static NSString *const kAVARegisters = @"registers";

@implementation AVAThreadFrame

- (NSMutableDictionary *)serializeToDictionary {
  NSMutableDictionary *dict = [NSMutableDictionary new];

  if (self.address) {
    dict[kAVAAddress] = self.address;
  }
  if (self.symbol) {
    dict[kAVASymbol] = self.symbol;
  }
  if (self.registers) {
    dict[kAVARegisters] = self.registers;
  }
  return dict;
}

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super init];
  if (self) {
    _address = [coder decodeObjectForKey:kAVAAddress];
    _symbol = [coder decodeObjectForKey:kAVASymbol];
    _registers = [coder decodeObjectForKey:kAVARegisters];
  }

  return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [coder encodeObject:self.address forKey:kAVAAddress];
  [coder encodeObject:self.symbol forKey:kAVASymbol];
  [coder encodeObject:self.registers forKey:kAVARegisters];
}

@end
