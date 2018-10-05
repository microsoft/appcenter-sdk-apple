#import "MSSemVer.h"
#import "MSTestFrameworks.h"

@interface MSSemVerTests : XCTestCase

@end

@implementation MSSemVerTests

- (void)testSemVerInit {

  // When
  MSSemVer *version = [MSSemVer semVerWithString:nil];

  // Then
  assertThat(version, nilValue());

  // When
  version = [MSSemVer semVerWithString:@"notSemVer"];

  // Then
  assertThat(version, nilValue());

  // When
  NSString *base = @"1.2.3";
  version = [MSSemVer semVerWithString:base];

  // Then
  assertThat(version.base, is(base));
  assertThat(version.preRelease, nilValue());
  assertThat(version.metadata, nilValue());

  // If
  base = @"1.2.3";
  NSString *preRelease = @"alpha";

  // When
  version = [MSSemVer semVerWithString:[NSString stringWithFormat:@"%@-%@", base, preRelease]];

  // Then
  assertThat(version.base, is(base));
  assertThat(version.preRelease, is(preRelease));
  assertThat(version.metadata, nilValue());

  // If
  base = @"1.2.3";
  preRelease = @"alpha";
  NSString *metadata = @"42meta";

  // When
  version = [MSSemVer semVerWithString:[NSString stringWithFormat:@"%@-%@+%@", base, preRelease, metadata]];

  // Then
  assertThat(version.base, is(base));
  assertThat(version.preRelease, is(preRelease));
  assertThat(version.metadata, is(metadata));

  // If
  base = @"1.2.3";
  metadata = @"42meta";

  // When
  version = [MSSemVer semVerWithString:[NSString stringWithFormat:@"%@+%@", base, metadata]];

  // Then
  assertThat(version.base, is(base));
  assertThat(version.preRelease, nilValue());
  assertThat(version.metadata, is(metadata));
}

- (void)testIsSemVerFormat {
  // Must match semVer format defined at http://semver.org/

  // If
  BOOL isSemVer;

  // When
  isSemVer = [MSSemVer isSemVerFormat:@"1"];

  // Then
  assertThatBool(isSemVer, isTrue());

  // When
  isSemVer = [MSSemVer isSemVerFormat:@"1.3"];

  // Then
  assertThatBool(isSemVer, isTrue());

  // When
  isSemVer = [MSSemVer isSemVerFormat:@"2.4.1"];

  // Then
  assertThatBool(isSemVer, isTrue());

  // When
  isSemVer = [MSSemVer isSemVerFormat:@"2.4.1-alpha"];

  // Then
  assertThatBool(isSemVer, isTrue());

  // When
  isSemVer = [MSSemVer isSemVerFormat:@"2.4.1-BETA"];

  // Then
  assertThatBool(isSemVer, isTrue());

  // When
  isSemVer = [MSSemVer isSemVerFormat:@"2.4.1-alpha-1"];

  // Then
  assertThatBool(isSemVer, isTrue());

  // When
  isSemVer = [MSSemVer isSemVerFormat:@"2.4.1-0.2.4"];

  // Then
  assertThatBool(isSemVer, isTrue());

  // When
  isSemVer = [MSSemVer isSemVerFormat:@"2.4.1-a.2.a.3"];

  // Then
  assertThatBool(isSemVer, isTrue());

  // When
  isSemVer = [MSSemVer isSemVerFormat:@"2.4.1-alpha+201"];

  // Then
  assertThatBool(isSemVer, isTrue());

  // When
  isSemVer = [MSSemVer isSemVerFormat:@"2.4.1-alpha+really"];

  // Then
  assertThatBool(isSemVer, isTrue());

  // When
  isSemVer = [MSSemVer isSemVerFormat:@"2.-4.1"];

  // Then
  assertThatBool(isSemVer, isFalse());

  // When
  isSemVer = [MSSemVer isSemVerFormat:@"2.4.1-"];

  // Then
  assertThatBool(isSemVer, isFalse());

  // When
  isSemVer = [MSSemVer isSemVerFormat:@"2.4.1-a#"];

  // Then
  assertThatBool(isSemVer, isFalse());

  // When
  isSemVer = [MSSemVer isSemVerFormat:@"2.04.1"];

  // Then
  assertThatBool(isSemVer, isFalse());

  // When
  isSemVer = [MSSemVer isSemVerFormat:@"1.3.4.0"];

  // Then
  assertThatBool(isSemVer, isFalse());

  // When
  isSemVer = [MSSemVer isSemVerFormat:@"1.3.0 2.1.4"];

  // Then
  assertThatBool(isSemVer, isFalse());

  // When
  isSemVer = [MSSemVer isSemVerFormat:@"1."];

  // Then
  assertThatBool(isSemVer, isFalse());

  // When
  isSemVer = [MSSemVer isSemVerFormat:@""];

  // Then
  assertThatBool(isSemVer, isFalse());

  // When
  isSemVer = [MSSemVer isSemVerFormat:nil];

  // Then
  assertThatBool(isSemVer, isFalse());

  // When
  isSemVer = [MSSemVer isSemVerFormat:@"a.b.c"];

  // Then
  assertThatBool(isSemVer, isFalse());

  // When
  isSemVer = [MSSemVer isSemVerFormat:@"a-1.2.4"];

  // Then
  assertThatBool(isSemVer, isFalse());

  // When
  isSemVer = [MSSemVer isSemVerFormat:@"a-1.2.4-b"];

  // Then
  assertThatBool(isSemVer, isFalse());
}

- (void)testSemVerComparison {

  // If
  // Check same versions.
  NSComparisonResult result;
  MSSemVer *verA = [MSSemVer semVerWithString:@"1.2.3"];
  MSSemVer *verB = [MSSemVer semVerWithString:@"1.2.3"];

  // When
  result = [verA compare:verB];

  // Then
  assertThatInt(result, equalToInt(NSOrderedSame));

  // If
  // Check ascending versions.
  verA = [MSSemVer semVerWithString:@"1.2.3"];
  verB = [MSSemVer semVerWithString:@"1.2.4"];

  // When
  result = [verA compare:verB];

  // Then
  assertThatInt(result, equalToInt(NSOrderedAscending));

  // If
  // Check descending versions.
  verA = [MSSemVer semVerWithString:@"1.2.4"];
  verB = [MSSemVer semVerWithString:@"1.2.3"];

  // When
  result = [verA compare:verB];

  // Then
  assertThatInt(result, equalToInt(NSOrderedDescending));

  // If
  // Alpha versions are lower precedence than normal versions.
  verA = [MSSemVer semVerWithString:@"1.2.3-Alpha"];
  verB = [MSSemVer semVerWithString:@"1.2.3"];

  // When
  result = [verA compare:verB];

  // Then
  assertThatInt(result, equalToInt(NSOrderedAscending));

  // If
  // Normal versions are higher precedence than alpha versions.
  verA = [MSSemVer semVerWithString:@"1.2.3"];
  verB = [MSSemVer semVerWithString:@"1.2.3-Alpha"];

  // When
  result = [verA compare:verB];

  // Then
  assertThatInt(result, equalToInt(NSOrderedDescending));

  // If
  // Can be multiple pre-release Ids.
  verA = [MSSemVer semVerWithString:@"1.2.3-A10.B3"];
  verB = [MSSemVer semVerWithString:@"1.2.3-A10.B4"];

  // When
  result = [verA compare:verB];

  // Then
  assertThatInt(result, equalToInt(NSOrderedAscending));

  // If
  // Metadata are ignored.
  verA = [MSSemVer semVerWithString:@"1.2.3"];
  verB = [MSSemVer semVerWithString:@"1.2.3+AE324F"];

  // When
  result = [verA compare:verB];

  // Then
  assertThatInt(result, equalToInt(NSOrderedSame));

  // If
  // The longest pre-release is higher precedence.
  verA = [MSSemVer semVerWithString:@"1.2.3-A10.23"];
  verB = [MSSemVer semVerWithString:@"1.2.3-A10.30"];

  // When
  result = [verA compare:verB];

  // Then
  assertThatInt(result, equalToInt(NSOrderedAscending));

  // If
  // Pre-release A starts with same identifiers but got more of them, it is
  // higher precedence.
  verA = [MSSemVer semVerWithString:@"1.2.3-A10.23"];
  verB = [MSSemVer semVerWithString:@"1.2.3-A10"];

  // When
  result = [verA compare:verB];

  // Then
  assertThatInt(result, equalToInt(NSOrderedDescending));

  // If
  // More pre-release ids is higher precedence.
  verA = [MSSemVer semVerWithString:@"1.2.3-A10.23"];
  verB = [MSSemVer semVerWithString:@"1.2.3-A10.23.10"];

  // When
  result = [verA compare:verB];

  // Then
  assertThatInt(result, equalToInt(NSOrderedAscending));
}

@end
