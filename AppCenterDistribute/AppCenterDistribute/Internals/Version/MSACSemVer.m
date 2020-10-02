// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSACSemVer.h"
#import "MSACSemVerPreReleaseId.h"

static NSString *const kMSACPreReleaseSeparator = @"-";
static NSString *const kMSACPreReleaseIdsSeparator = @".";
static NSString *const kMSACMetaDataSeparator = @"+";

@implementation MSACSemVer

+ (instancetype)semVerWithString:(nullable NSString *)version {
  return [[MSACSemVer alloc] initWithString:(NSString *)version];
}

- (instancetype)initWithString:(nullable NSString *)version {

  // Validate.
  if (![[self class] isSemVerFormat:version]) {
    return nil;
  }

  // Initialize.
  if ((self = [super init])) {
    NSRange preReleaseSepRange = [version rangeOfString:kMSACPreReleaseSeparator];
    NSRange metadataSepRange = [version rangeOfString:kMSACMetaDataSeparator];
    _base = (NSString * _Nonnull) version;
    if (metadataSepRange.length > 0) {
      _base = (NSString * _Nonnull)[version substringToIndex:metadataSepRange.location];
      _metadata = [version substringFromIndex:metadataSepRange.location + 1];
    }
    if (preReleaseSepRange.length > 0) {
      _preRelease = [_base substringFromIndex:preReleaseSepRange.location + 1];
      _base = (NSString * _Nonnull)[version substringToIndex:preReleaseSepRange.location];
    }
  }
  return self;
}

- (NSComparisonResult)compare:(MSACSemVer *)version {

  // Compare base version first.
  __block NSComparisonResult comparisonResult = [self.base compare:version.base options:NSNumericSearch];

  // If same then compare pre-release.
  if (comparisonResult == NSOrderedSame) {
    NSString *preReleaseA = self.preRelease;
    NSString *preReleaseB = version.preRelease;

    // No/same pre-release.
    if ((!preReleaseA && !preReleaseB) || [preReleaseA isEqualToString:(NSString * _Nonnull) preReleaseB]) {
      return NSOrderedSame;
    }

    // Pre-release versions have lower precedence than normal versions.
    if (!preReleaseA && preReleaseB) {
      return NSOrderedDescending;
    }
    if (preReleaseA && !preReleaseB) {
      return NSOrderedAscending;
    }

    // Compare pre-release identifiers.
    NSArray<NSString *> *preReleaseAIds = [preReleaseA componentsSeparatedByString:kMSACPreReleaseIdsSeparator];
    NSArray<NSString *> *preReleaseBIds = [preReleaseB componentsSeparatedByString:kMSACPreReleaseIdsSeparator];
    [preReleaseAIds enumerateObjectsUsingBlock:^(NSString *_Nonnull identifier, NSUInteger idx, BOOL *_Nonnull stop) {
      MSACSemVerPreReleaseId *identifierA = [MSACSemVerPreReleaseId identifierWithString:identifier];
      MSACSemVerPreReleaseId *identifierB =
          (preReleaseBIds.count > idx) ? [MSACSemVerPreReleaseId identifierWithString:preReleaseBIds[idx]] : nil;
      if (identifierB) {
        comparisonResult = [identifierA compare:identifierB];
        if (comparisonResult != NSOrderedSame) {
          *stop = YES;
        }
      } else {

        // Pre-release A starts with same identifiers but got more of them, it's higher precedence.
        comparisonResult = NSOrderedDescending;
        *stop = YES;
      }
    }];

    // Pre-release B starts with same identifiers but got more of them, it's higher precedence.
    if (comparisonResult == NSOrderedSame && preReleaseBIds.count > preReleaseAIds.count) {
      return NSOrderedAscending;
    }
  }
  return comparisonResult;
}

+ (BOOL)isSemVerFormat:(NSString *)version {
  NSString *semVerPattern = @"^v?(?:0|[1-9]\\d*)(\\.(?:[x*]|0|[1-9]\\d*)(\\.(?:[x*]|0|[1-9]\\d*)(?:-["
                            @"\\da-z\\-]+(?:\\.["
                            @"\\da-z\\-]+)*)?(?:\\+[\\da-z\\-]+(?:\\.[\\da-z\\-]+)*)?)?)?$";
  NSPredicate *myTest = [NSPredicate predicateWithFormat:@"SELF MATCHES[c]  %@", semVerPattern];
  return [myTest evaluateWithObject:version];
}

@end
