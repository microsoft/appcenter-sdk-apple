// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSHttpUtil.h"
#import "MSTestFrameworks.h"

@interface MSHttpUtilTests : XCTestCase

@end

@implementation MSHttpUtilTests

- (void)testLargeSecret {

  // If
  NSString *secret = @"shhhh-its-a-secret";
  NSString *hiddenSecret;

  // When
  hiddenSecret = [MSHttpUtil hideSecret:secret];

  // Then
  NSString *fullyHiddenSecret = [@"" stringByPaddingToLength:hiddenSecret.length withString:kMSHidingStringForAppSecret startingAtIndex:0];
  NSString *appSecretHiddenPart = [hiddenSecret commonPrefixWithString:fullyHiddenSecret options:0];
  NSString *appSecretVisiblePart = [hiddenSecret substringFromIndex:appSecretHiddenPart.length];
  assertThatInteger(secret.length - appSecretHiddenPart.length, equalToShort(kMSMaxCharactersDisplayedForAppSecret));
  assertThat(appSecretVisiblePart, is([secret substringFromIndex:appSecretHiddenPart.length]));
}

- (void)testShortSecret {

  // If
  NSString *secret = @"";
  for (short i = 1; i <= kMSMaxCharactersDisplayedForAppSecret - 1; i++)
    secret = [NSString stringWithFormat:@"%@%hd", secret, i];
  NSString *hiddenSecret;

  // When
  hiddenSecret = [MSHttpUtil hideSecret:secret];

  // Then
  NSString *fullyHiddenSecret = [@"" stringByPaddingToLength:hiddenSecret.length withString:kMSHidingStringForAppSecret startingAtIndex:0];
  assertThatInteger(hiddenSecret.length, equalToUnsignedInteger(secret.length));
  assertThat(hiddenSecret, is(fullyHiddenSecret));
}

- (void)testIsNoInternetConnectionError {

  // When
  NSError *error = [[NSError alloc] initWithDomain:NSURLErrorDomain code:NSURLErrorNotConnectedToInternet userInfo:nil];

  // Then
  XCTAssertTrue([MSHttpUtil isNoInternetConnectionError:error]);

  // When
  error = [[NSError alloc] initWithDomain:NSURLErrorDomain code:NSURLErrorNetworkConnectionLost userInfo:nil];

  // Then
  XCTAssertTrue([MSHttpUtil isNoInternetConnectionError:error]);

  // When
  error = [[NSError alloc] initWithDomain:NSURLErrorDomain code:NSURLErrorServerCertificateHasBadDate userInfo:nil];

  // Then
  XCTAssertFalse([MSHttpUtil isNoInternetConnectionError:error]);
}

- (void)testSSLConnectionErrorDetected {

  // When
  NSError *error = [[NSError alloc] initWithDomain:NSURLErrorDomain code:NSURLErrorSecureConnectionFailed userInfo:nil];

  // Then
  XCTAssertTrue([MSHttpUtil isSSLConnectionError:error]);

  // When
  error = [[NSError alloc] initWithDomain:NSURLErrorDomain code:NSURLErrorServerCertificateHasBadDate userInfo:nil];

  // Then
  XCTAssertTrue([MSHttpUtil isSSLConnectionError:error]);

  // When
  error = [[NSError alloc] initWithDomain:NSURLErrorDomain code:NSURLErrorServerCertificateUntrusted userInfo:nil];

  // Then
  XCTAssertTrue([MSHttpUtil isSSLConnectionError:error]);

  // When
  error = [[NSError alloc] initWithDomain:NSURLErrorDomain code:NSURLErrorServerCertificateHasUnknownRoot userInfo:nil];

  // Then
  XCTAssertTrue([MSHttpUtil isSSLConnectionError:error]);

  // When
  error = [[NSError alloc] initWithDomain:NSURLErrorDomain code:NSURLErrorServerCertificateNotYetValid userInfo:nil];

  // Then
  XCTAssertTrue([MSHttpUtil isSSLConnectionError:error]);

  // When
  error = [[NSError alloc] initWithDomain:NSURLErrorDomain code:NSURLErrorClientCertificateRejected userInfo:nil];

  // Then
  XCTAssertTrue([MSHttpUtil isSSLConnectionError:error]);

  // When
  error = [[NSError alloc] initWithDomain:NSURLErrorDomain code:NSURLErrorClientCertificateRequired userInfo:nil];

  // Then
  XCTAssertTrue([MSHttpUtil isSSLConnectionError:error]);

  // When
  error = [[NSError alloc] initWithDomain:NSURLErrorDomain code:NSURLErrorCannotLoadFromNetwork userInfo:nil];

  // Then
  XCTAssertTrue([MSHttpUtil isSSLConnectionError:error]);

  // When
  error = [[NSError alloc] initWithDomain:NSURLErrorFailingURLErrorKey code:NSURLErrorCannotLoadFromNetwork userInfo:nil];

  // Then
  XCTAssertFalse([MSHttpUtil isSSLConnectionError:error]);

  // When
  error = [[NSError alloc] initWithDomain:NSURLErrorDomain code:10 userInfo:nil];

  // Then
  XCTAssertFalse([MSHttpUtil isSSLConnectionError:error]);
}

- (void)testIsRecoverableError {
  for (int i = 0; i < 530; i++) {

    // When
    BOOL result = [MSHttpUtil isRecoverableError:i];

    // Then
    if (i >= 500) {
      XCTAssertTrue(result);
    } else if (i == 408) {
      XCTAssertTrue(result);
    } else if (i == 429) {
      XCTAssertTrue(result);
    } else if (i == 0) {
      XCTAssertTrue(result);
    } else {
      XCTAssertFalse(result);
    }
  }
}

@end
