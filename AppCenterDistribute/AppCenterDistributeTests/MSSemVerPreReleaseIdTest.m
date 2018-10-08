#import "MSSemVerPreReleaseId.h"
#import "MSTestFrameworks.h"

@interface MSSemVerPreReleaseIdTests : XCTestCase

@end

@implementation MSSemVerPreReleaseIdTests

- (void)testSemVerPreReleaseIdInit {

  // If
  NSString *idString = nil;
  MSSemVerPreReleaseId *preReleaseId = [MSSemVerPreReleaseId identifierWithString:idString];

  // Then
  assertThat(preReleaseId, nilValue());

  // If
  preReleaseId = [MSSemVerPreReleaseId identifierWithString:@""];

  // Then
  assertThat(preReleaseId, nilValue());

  // If
  idString = @"beta";
  preReleaseId = [MSSemVerPreReleaseId identifierWithString:idString];

  // Then
  assertThat(preReleaseId.identifier, is(idString));
}

- (void)testSemVerPreReleaseIdComparison {

  // If
  // Equal pre-releases ids.
  MSSemVerPreReleaseId *preReleaseIdA = [MSSemVerPreReleaseId identifierWithString:@"alpha"];
  MSSemVerPreReleaseId *preReleaseIdB = [MSSemVerPreReleaseId identifierWithString:@"alpha"];

  // When
  NSComparisonResult result = [preReleaseIdA compare:preReleaseIdB];

  // Then
  assertThatInt(result, equalToInt(NSOrderedSame));

  // If
  // Numerical identifiers in pre-release are compared as numeric values.
  preReleaseIdA = [MSSemVerPreReleaseId identifierWithString:@"12"];
  preReleaseIdB = [MSSemVerPreReleaseId identifierWithString:@"13"];

  // When
  result = [preReleaseIdA compare:preReleaseIdB];

  // Then
  assertThatInt(result, equalToInt(NSOrderedAscending));

  // If
  // Numerical identifiers in pre-release are compared as numeric values.
  preReleaseIdA = [MSSemVerPreReleaseId identifierWithString:@"13"];
  preReleaseIdB = [MSSemVerPreReleaseId identifierWithString:@"12"];

  // When
  result = [preReleaseIdA compare:preReleaseIdB];

  // Then
  assertThatInt(result, equalToInt(NSOrderedDescending));

  // If
  // Alphanumerical identifiers in pre-release are compared using ASCII order.
  preReleaseIdA = [MSSemVerPreReleaseId identifierWithString:@"AZ"];
  preReleaseIdB = [MSSemVerPreReleaseId identifierWithString:@"Az"];

  // When
  result = [preReleaseIdA compare:preReleaseIdB];

  // Then
  assertThatInt(result, equalToInt(NSOrderedAscending));

  // If
  // Alphanumerical identifiers in pre-release are compared using ASCII order.
  preReleaseIdA = [MSSemVerPreReleaseId identifierWithString:@"Az"];
  preReleaseIdB = [MSSemVerPreReleaseId identifierWithString:@"AZ"];

  // When
  result = [preReleaseIdA compare:preReleaseIdB];

  // Then
  assertThatInt(result, equalToInt(NSOrderedDescending));

  // If
  // Numbers have lower precedence than alphanumeric values for pre-release
  // identifiers.
  preReleaseIdA = [MSSemVerPreReleaseId identifierWithString:@"123"];
  preReleaseIdB = [MSSemVerPreReleaseId identifierWithString:@"A10"];

  // When
  result = [preReleaseIdA compare:preReleaseIdB];

  // Then
  assertThatInt(result, equalToInt(NSOrderedAscending));

  // If
  // The longest pre-release identifier is higher precedence.
  preReleaseIdA = [MSSemVerPreReleaseId identifierWithString:@"A10"];
  preReleaseIdB = [MSSemVerPreReleaseId identifierWithString:@"A10a"];

  // When
  result = [preReleaseIdA compare:preReleaseIdB];

  // Then
  assertThatInt(result, equalToInt(NSOrderedAscending));

  // If
  // The pre-release numeric identifier is lower precedence.
  preReleaseIdA = [MSSemVerPreReleaseId identifierWithString:@"A"];
  preReleaseIdB = [MSSemVerPreReleaseId identifierWithString:@"10"];

  // When
  result = [preReleaseIdA compare:preReleaseIdB];

  // Then
  assertThatInt(result, equalToInt(NSOrderedDescending));
}

@end
