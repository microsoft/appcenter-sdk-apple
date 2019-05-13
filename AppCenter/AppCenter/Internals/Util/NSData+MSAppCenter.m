// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "NSData+MSAppCenter.h"

@implementation NSData (MSAppCenter)

- (size_t)locationOfString:(NSString *)string usingEncoding:(NSStringEncoding)encoding {
  NSData *stringAsData = [string dataUsingEncoding:encoding];
  NSRange entireRange = NSMakeRange(0, [self length]);
  return [self rangeOfData:stringAsData options:0 range:entireRange].location;
}

- (NSString *)stringFromRange:(NSRange)range usingEncoding:(NSStringEncoding)encoding {
  NSData *subdata = [self subdataWithRange:range];
  return [[NSString alloc] initWithData:subdata encoding:encoding];
}

@end
