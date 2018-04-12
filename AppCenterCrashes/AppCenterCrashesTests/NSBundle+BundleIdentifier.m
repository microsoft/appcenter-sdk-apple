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
