#import "MSSemVer.h"
#import "MSSemVerPreReleaseId.h"

static NSString *const kMSPreReleaseSeparator = @"-";
static NSString *const kMSPreReleaseIdsSeparator = @".";
static NSString *const kMSMetaDataSeparator = @"+";

@implementation MSSemVer

+ (instancetype)semVerWithString:(nullable NSString *)version {
  return [[MSSemVer alloc] initWithString:(NSString *)version];
}

- (instancetype)initWithString:(nullable NSString *)version {

  // Validate.
  if (![[self class] isSemVerFormat:version]) {
    return nil;
  }

  // Initialize.
  if ((self = [super init])) {
    NSRange preReleaseSepRange = [version rangeOfString:kMSPreReleaseSeparator];
    NSRange metadataSepRange = [version rangeOfString:kMSMetaDataSeparator];
    _base = (NSString * _Nonnull)version;
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

- (NSComparisonResult)compare:(MSSemVer *)version {

  // Compare base version first.
  __block NSComparisonResult comparisonResult = [self.base compare:version.base options:NSNumericSearch];

  // If same then compare pre-release.
  if (comparisonResult == NSOrderedSame) {
    NSString *preReleaseA = self.preRelease;
    NSString *preReleaseB = version.preRelease;

    // No/same pre-release.
    if ((!preReleaseA && !preReleaseB) || [preReleaseA isEqualToString:(NSString * _Nonnull)preReleaseB]) {
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
    NSArray<NSString *> *preReleaseAIds = [preReleaseA componentsSeparatedByString:kMSPreReleaseIdsSeparator];
    NSArray<NSString *> *preReleaseBIds = [preReleaseB componentsSeparatedByString:kMSPreReleaseIdsSeparator];
    [preReleaseAIds enumerateObjectsUsingBlock:^(NSString *_Nonnull identifier, NSUInteger idx, BOOL *_Nonnull stop) {
      MSSemVerPreReleaseId *identifierA = [MSSemVerPreReleaseId identifierWithString:identifier];
      MSSemVerPreReleaseId *identifierB =
          (preReleaseBIds.count > idx) ? [MSSemVerPreReleaseId identifierWithString:preReleaseBIds[idx]] : nil;
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
