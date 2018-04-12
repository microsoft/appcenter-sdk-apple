//
//  NSBundle+BundleIdentifier.m
//  AppCenterCrashes
//
//  Created by Benjamin Scholtysik on 4/11/18.
//  Copyright © 2018 Microsoft. All rights reserved.
//

#import "NSBundle+BundleIdentifier.h"

@implementation NSBundle (BundleIdentifier)

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-protocol-method-implementation"
-(NSString *)bundleIdentifier
{
  return @"com.test.app";
}
#pragma clang diagnostic pop

@end
