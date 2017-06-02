#import "MSIngestionSender.h"
#import "MSTestFrameworks.h"

@interface MSSenderUtilTests : XCTestCase

@end

@implementation MSSenderUtilTests

- (void)testLargeSecret {

  // If.
  NSString *secret = @"shhhh-its-a-secret";
  NSString *hiddenSecret;

  // When.
  hiddenSecret = [MSSenderUtil hideSecret:secret];

  // Then.
  NSString *fullyHiddenSecret =
      [@"" stringByPaddingToLength:hiddenSecret.length withString:kMSHidingStringForAppSecret startingAtIndex:0];
  NSString *appSecretHiddenPart = [hiddenSecret commonPrefixWithString:fullyHiddenSecret options:0];
  NSString *appSecretVisiblePart = [hiddenSecret substringFromIndex:appSecretHiddenPart.length];
  assertThatInteger(secret.length - appSecretHiddenPart.length, equalToShort(kMSMaxCharactersDisplayedForAppSecret));
  assertThat(appSecretVisiblePart, is([secret substringFromIndex:appSecretHiddenPart.length]));
}

- (void)testShortSecret {

  // If.
  NSString *secret = @"";
  for (short i = 1; i <= kMSMaxCharactersDisplayedForAppSecret - 1; i++)
    secret = [NSString stringWithFormat:@"%@%hd", secret, i];
  NSString *hiddenSecret;

  // When.
  hiddenSecret = [MSSenderUtil hideSecret:secret];

  // Then.
  NSString *fullyHiddenSecret =
      [@"" stringByPaddingToLength:hiddenSecret.length withString:kMSHidingStringForAppSecret startingAtIndex:0];
  assertThatInteger(hiddenSecret.length, equalToInteger(secret.length));
  assertThat(hiddenSecret, is(fullyHiddenSecret));
}

@end
