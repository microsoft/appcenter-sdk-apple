// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "NSObject+MSTestFixture.h"

@implementation NSObject (MSTestFixture)

- (NSData *)jsonFixture:(NSString *)fixture {
  NSBundle *bundle = [NSBundle bundleForClass:[self class]];
  NSString *path = [bundle pathForResource:fixture ofType:@"json"];
  return [NSData dataWithContentsOfFile:path];
}

@end
