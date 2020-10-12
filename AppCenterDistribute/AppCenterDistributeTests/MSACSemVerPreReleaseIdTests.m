// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSACSemVerPreReleaseId.h"
#import "MSACTestFrameworks.h"

@interface MSACSemVerPreReleaseIdTests : XCTestCase

@end

@implementation MSACSemVerPreReleaseIdTests

- (void)testSemVerPreReleaseIdInit {

  // If
  NSString *idString = nil;
  MSACSemVerPreReleaseId *preReleaseId = [MSACSemVerPreReleaseId identifierWithString:idString];

  // Then
  assertThat(preReleaseId, nilValue());

  // If
  preReleaseId = [MSACSemVerPreReleaseId identifierWithString:@""];

  // Then
  assertThat(preReleaseId, nilValue());

  // If
  idString = @"beta";
  preReleaseId = [MSACSemVerPreReleaseId identifierWithString:idString];

  // Then
  assertThat(preReleaseId.identifier, is(idString));
}

- (void)testSemVerPreReleaseIdComparison {

  // If
  // Equal pre-releases ids.
  MSACSemVerPreReleaseId *preReleaseIdA = [MSACSemVerPreReleaseId identifierWithString:@"alpha"];
  MSACSemVerPreReleaseId *preReleaseIdB = [MSACSemVerPreReleaseId identifierWithString:@"alpha"];

  // When
  NSComparisonResult result = [preReleaseIdA compare:preReleaseIdB];

  // Then
  assertThatInt(result, equalToInt(NSOrderedSame));

  // If
  // Numerical identifiers in pre-release are compared as numeric values.
  preReleaseIdA = [MSACSemVerPreReleaseId identifierWithString:@"12"];
  preReleaseIdB = [MSACSemVerPreReleaseId identifierWithString:@"13"];

  // When
  result = [preReleaseIdA compare:preReleaseIdB];

  // Then
  assertThatInt(result, equalToInt(NSOrderedAscending));

  // If
  // Numerical identifiers in pre-release are compared as numeric values.
  preReleaseIdA = [MSACSemVerPreReleaseId identifierWithString:@"13"];
  preReleaseIdB = [MSACSemVerPreReleaseId identifierWithString:@"12"];

  // When
  result = [preReleaseIdA compare:preReleaseIdB];

  // Then
  assertThatInt(result, equalToInt(NSOrderedDescending));

  // If
  // Alphanumerical identifiers in pre-release are compared using ASCII order.
  preReleaseIdA = [MSACSemVerPreReleaseId identifierWithString:@"AZ"];
  preReleaseIdB = [MSACSemVerPreReleaseId identifierWithString:@"Az"];

  // When
  result = [preReleaseIdA compare:preReleaseIdB];

  // Then
  assertThatInt(result, equalToInt(NSOrderedAscending));

  // If
  // Alphanumerical identifiers in pre-release are compared using ASCII order.
  preReleaseIdA = [MSACSemVerPreReleaseId identifierWithString:@"Az"];
  preReleaseIdB = [MSACSemVerPreReleaseId identifierWithString:@"AZ"];

  // When
  result = [preReleaseIdA compare:preReleaseIdB];

  // Then
  assertThatInt(result, equalToInt(NSOrderedDescending));

  // If
  // Numbers have lower precedence than alphanumeric values for pre-release
  // identifiers.
  preReleaseIdA = [MSACSemVerPreReleaseId identifierWithString:@"123"];
  preReleaseIdB = [MSACSemVerPreReleaseId identifierWithString:@"A10"];

  // When
  result = [preReleaseIdA compare:preReleaseIdB];

  // Then
  assertThatInt(result, equalToInt(NSOrderedAscending));

  // If
  // The longest pre-release identifier is higher precedence.
  preReleaseIdA = [MSACSemVerPreReleaseId identifierWithString:@"A10"];
  preReleaseIdB = [MSACSemVerPreReleaseId identifierWithString:@"A10a"];

  // When
  result = [preReleaseIdA compare:preReleaseIdB];

  // Then
  assertThatInt(result, equalToInt(NSOrderedAscending));

  // If
  // The pre-release numeric identifier is lower precedence.
  preReleaseIdA = [MSACSemVerPreReleaseId identifierWithString:@"A"];
  preReleaseIdB = [MSACSemVerPreReleaseId identifierWithString:@"10"];

  // When
  result = [preReleaseIdA compare:preReleaseIdB];

  // Then
  assertThatInt(result, equalToInt(NSOrderedDescending));
}

@end
