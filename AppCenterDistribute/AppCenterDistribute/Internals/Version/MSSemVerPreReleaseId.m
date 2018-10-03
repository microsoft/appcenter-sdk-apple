#import "MSSemVerPreReleaseId.h"

@implementation MSSemVerPreReleaseId

+ (instancetype)identifierWithString:(NSString *)identifier {
  return [[MSSemVerPreReleaseId alloc] initWithString:identifier];
}

- (instancetype)initWithString:(NSString *)identifier {

  // Validate.
  if (!(identifier.length > 0)) {
    return nil;
  }

  // Initialize.
  if ((self = [super init])) {
    _identifier = identifier;
  }
  return self;
}

- (NSComparisonResult)compare:(MSSemVerPreReleaseId *)identifier {
  NSString *identifierA = self.identifier;
  NSString *identifierB = identifier.identifier;
  NSNumber *idANumValue;
  NSNumber *idBNumValue;
  NSUInteger idALength;
  NSUInteger idBLength;

  // Strictly identical, return it now.
  if ([identifierA isEqualToString:identifierB]) {
    return NSOrderedSame;
  }

  // Compare by numeric values.
  idANumValue = [self numberValue];
  idBNumValue = [identifier numberValue];
  if (idANumValue && idBNumValue) {
    return [idANumValue compare:idBNumValue];
  }

  // A is a number but not B.
  if (idANumValue && !idBNumValue) {
    return NSOrderedAscending;
  }

  // B is a number but not A.
  if (!idANumValue && idBNumValue) {
    return NSOrderedDescending;
  }

  // None is numeric only, compare by ASCII order.
  idALength = identifierA.length;
  idBLength = identifierB.length;
  const char *idAASCIIChars = [identifierA cStringUsingEncoding:NSASCIIStringEncoding];
  const char *idBASCIIChars = [identifierB cStringUsingEncoding:NSASCIIStringEncoding];
  for (NSUInteger i = 0; i < MIN(idALength, idBLength); i++) {
    if (*(idAASCIIChars + i) > *(idBASCIIChars + i)) {
      return NSOrderedDescending;
    } else if (*(idAASCIIChars + i) < *(idBASCIIChars + i)) {
      return NSOrderedAscending;
    }
  }

  /*
   * At this point we know that:
   *  - Identifiers are not equals.
   *  - Identifiers contains alphanumeric values.
   *  - One identifier starts with the same characters but is longer than the other.
   *
   * The final decision now relies on identifiers' length, the longest is higher precedence.
   */
  return (idALength < idBLength) ? NSOrderedAscending : NSOrderedDescending;
}

- (nullable NSNumber *)numberValue {
  NSNumberFormatter *nformatter = [NSNumberFormatter new];
  nformatter.numberStyle = NSNumberFormatterNoStyle;
  return [nformatter numberFromString:self.identifier];
}

@end
