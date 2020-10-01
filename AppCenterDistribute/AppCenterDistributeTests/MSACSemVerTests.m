// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSACSemVer.h"
#import "MSACTestFrameworks.h"

@interface MSACSemVerTests : XCTestCase

@end

@implementation MSACSemVerTests

- (void)testSemVerInit {

  // When
  MSACSemVer *version = [MSACSemVer semVerWithString:nil];

  // Then
  assertThat(version, nilValue());

  // When
  version = [MSACSemVer semVerWithString:@"notSemVer"];

  // Then
  assertThat(version, nilValue());

  // When
  NSString *base = @"1.2.3";
  version = [MSACSemVer semVerWithString:base];

  // Then
  assertThat(version.base, is(base));
  assertThat(version.preRelease, nilValue());
  assertThat(version.metadata, nilValue());

  // If
  base = @"1.2.3";
  NSString *preRelease = @"alpha";

  // When
  version = [MSACSemVer semVerWithString:[NSString stringWithFormat:@"%@-%@", base, preRelease]];

  // Then
  assertThat(version.base, is(base));
  assertThat(version.preRelease, is(preRelease));
  assertThat(version.metadata, nilValue());

  // If
  base = @"1.2.3";
  preRelease = @"alpha";
  NSString *metadata = @"42meta";

  // When
  version = [MSACSemVer semVerWithString:[NSString stringWithFormat:@"%@-%@+%@", base, preRelease, metadata]];

  // Then
  assertThat(version.base, is(base));
  assertThat(version.preRelease, is(preRelease));
  assertThat(version.metadata, is(metadata));

  // If
  base = @"1.2.3";
  metadata = @"42meta";

  // When
  version = [MSACSemVer semVerWithString:[NSString stringWithFormat:@"%@+%@", base, metadata]];

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
  isSemVer = [MSACSemVer isSemVerFormat:@"1"];

  // Then
  assertThatBool(isSemVer, isTrue());

  // When
  isSemVer = [MSACSemVer isSemVerFormat:@"1.3"];

  // Then
  assertThatBool(isSemVer, isTrue());

  // When
  isSemVer = [MSACSemVer isSemVerFormat:@"2.4.1"];

  // Then
  assertThatBool(isSemVer, isTrue());

  // When
  isSemVer = [MSACSemVer isSemVerFormat:@"2.4.1-alpha"];

  // Then
  assertThatBool(isSemVer, isTrue());

  // When
  isSemVer = [MSACSemVer isSemVerFormat:@"2.4.1-BETA"];

  // Then
  assertThatBool(isSemVer, isTrue());

  // When
  isSemVer = [MSACSemVer isSemVerFormat:@"2.4.1-alpha-1"];

  // Then
  assertThatBool(isSemVer, isTrue());

  // When
  isSemVer = [MSACSemVer isSemVerFormat:@"2.4.1-0.2.4"];

  // Then
  assertThatBool(isSemVer, isTrue());

  // When
  isSemVer = [MSACSemVer isSemVerFormat:@"2.4.1-a.2.a.3"];

  // Then
  assertThatBool(isSemVer, isTrue());

  // When
  isSemVer = [MSACSemVer isSemVerFormat:@"2.4.1-alpha+201"];

  // Then
  assertThatBool(isSemVer, isTrue());

  // When
  isSemVer = [MSACSemVer isSemVerFormat:@"2.4.1-alpha+really"];

  // Then
  assertThatBool(isSemVer, isTrue());

  // When
  isSemVer = [MSACSemVer isSemVerFormat:@"2.-4.1"];

  // Then
  assertThatBool(isSemVer, isFalse());

  // When
  isSemVer = [MSACSemVer isSemVerFormat:@"2.4.1-"];

  // Then
  assertThatBool(isSemVer, isFalse());

  // When
  isSemVer = [MSACSemVer isSemVerFormat:@"2.4.1-a#"];

  // Then
  assertThatBool(isSemVer, isFalse());

  // When
  isSemVer = [MSACSemVer isSemVerFormat:@"2.04.1"];

  // Then
  assertThatBool(isSemVer, isFalse());

  // When
  isSemVer = [MSACSemVer isSemVerFormat:@"1.3.4.0"];

  // Then
  assertThatBool(isSemVer, isFalse());

  // When
  isSemVer = [MSACSemVer isSemVerFormat:@"1.3.0 2.1.4"];

  // Then
  assertThatBool(isSemVer, isFalse());

  // When
  isSemVer = [MSACSemVer isSemVerFormat:@"1."];

  // Then
  assertThatBool(isSemVer, isFalse());

  // When
  isSemVer = [MSACSemVer isSemVerFormat:@""];

  // Then
  assertThatBool(isSemVer, isFalse());

  // When
  isSemVer = [MSACSemVer isSemVerFormat:nil];

  // Then
  assertThatBool(isSemVer, isFalse());

  // When
  isSemVer = [MSACSemVer isSemVerFormat:@"a.b.c"];

  // Then
  assertThatBool(isSemVer, isFalse());

  // When
  isSemVer = [MSACSemVer isSemVerFormat:@"a-1.2.4"];

  // Then
  assertThatBool(isSemVer, isFalse());

  // When
  isSemVer = [MSACSemVer isSemVerFormat:@"a-1.2.4-b"];

  // Then
  assertThatBool(isSemVer, isFalse());
}

- (void)testSemVerComparison {

  // If
  // Check same versions.
  NSComparisonResult result;
  MSACSemVer *verA = [MSACSemVer semVerWithString:@"1.2.3"];
  MSACSemVer *verB = [MSACSemVer semVerWithString:@"1.2.3"];

  // When
  result = [verA compare:verB];

  // Then
  assertThatInt(result, equalToInt(NSOrderedSame));

  // If
  // Check ascending versions.
  verA = [MSACSemVer semVerWithString:@"1.2.3"];
  verB = [MSACSemVer semVerWithString:@"1.2.4"];

  // When
  result = [verA compare:verB];

  // Then
  assertThatInt(result, equalToInt(NSOrderedAscending));

  // If
  // Check descending versions.
  verA = [MSACSemVer semVerWithString:@"1.2.4"];
  verB = [MSACSemVer semVerWithString:@"1.2.3"];

  // When
  result = [verA compare:verB];

  // Then
  assertThatInt(result, equalToInt(NSOrderedDescending));

  // If
  // Alpha versions are lower precedence than normal versions.
  verA = [MSACSemVer semVerWithString:@"1.2.3-Alpha"];
  verB = [MSACSemVer semVerWithString:@"1.2.3"];

  // When
  result = [verA compare:verB];

  // Then
  assertThatInt(result, equalToInt(NSOrderedAscending));

  // If
  // Normal versions are higher precedence than alpha versions.
  verA = [MSACSemVer semVerWithString:@"1.2.3"];
  verB = [MSACSemVer semVerWithString:@"1.2.3-Alpha"];

  // When
  result = [verA compare:verB];

  // Then
  assertThatInt(result, equalToInt(NSOrderedDescending));

  // If
  // Can be multiple pre-release Ids.
  verA = [MSACSemVer semVerWithString:@"1.2.3-A10.B3"];
  verB = [MSACSemVer semVerWithString:@"1.2.3-A10.B4"];

  // When
  result = [verA compare:verB];

  // Then
  assertThatInt(result, equalToInt(NSOrderedAscending));

  // If
  // Metadata are ignored.
  verA = [MSACSemVer semVerWithString:@"1.2.3"];
  verB = [MSACSemVer semVerWithString:@"1.2.3+AE324F"];

  // When
  result = [verA compare:verB];

  // Then
  assertThatInt(result, equalToInt(NSOrderedSame));

  // If
  // The longest pre-release is higher precedence.
  verA = [MSACSemVer semVerWithString:@"1.2.3-A10.23"];
  verB = [MSACSemVer semVerWithString:@"1.2.3-A10.30"];

  // When
  result = [verA compare:verB];

  // Then
  assertThatInt(result, equalToInt(NSOrderedAscending));

  // If
  // Pre-release A starts with same identifiers but got more of them, it is
  // higher precedence.
  verA = [MSACSemVer semVerWithString:@"1.2.3-A10.23"];
  verB = [MSACSemVer semVerWithString:@"1.2.3-A10"];

  // When
  result = [verA compare:verB];

  // Then
  assertThatInt(result, equalToInt(NSOrderedDescending));

  // If
  // More pre-release ids is higher precedence.
  verA = [MSACSemVer semVerWithString:@"1.2.3-A10.23"];
  verB = [MSACSemVer semVerWithString:@"1.2.3-A10.23.10"];

  // When
  result = [verA compare:verB];

  // Then
  assertThatInt(result, equalToInt(NSOrderedAscending));
}

@end
