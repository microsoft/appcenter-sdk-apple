// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

#import "MSTestDocument.h"

@implementation MSTestDocument

@synthesize property1 = _property1;
@synthesize property2 = _property2;

- (instancetype)initFromDictionary:(NSDictionary *)dictionary {
  self.property1 = dictionary[@"property1"];
  self.property2 = dictionary[@"property2"];
  return self;
}

- (nonnull NSDictionary *)serializeToDictionary {
  return [NSDictionary new];
}

+ (NSData *)getDocumentFixture:(NSString *)fixture {

  // Return the fixture.
  NSBundle *bundle = [NSBundle bundleForClass:[self class]];
  NSString *path = [bundle pathForResource:fixture ofType:@"json"];
  return [NSData dataWithContentsOfFile:path];
}

@end
