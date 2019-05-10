// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSConstants+Internal.h"
#import "MSEncrypterPrivate.h"
#import "MSMockKeychainUtil.h"
#import "MSMockUserDefaults.h"
#import "MSTestFrameworks.h"
#import "MSUtility+Date.h"
#import "MSTestFrameworks.h"

@interface MSEncrypterTests : XCTestCase

@property(nonatomic) id keychainUtilMock;

@end

@implementation MSEncrypterTests

- (void)setUp {
  [super setUp];
  self.keychainUtilMock = [MSMockKeychainUtil new];
}

- (void)tearDown {
  [self.keychainUtilMock stopMocking];
  [MSEncrypter deleteKeyWithTag:kMSEncryptionKeyTagOriginal];
}

- (void)testEncryption {

  // If
  MSEncrypter *encrypter = [[MSEncrypter alloc] initWitKeyTag:kMSEncryptionKeyTagOriginal];
  NSString *stringToEncrypt = @"Test string";

  // When
  NSString *encrypted = [encrypter encryptString:stringToEncrypt];

  // Then
  XCTAssertNotEqualObjects(encrypted, stringToEncrypt);

  // When
  NSString *decrypted = [encrypter decryptString:encrypted];

  // Then
  XCTAssertEqualObjects(decrypted, stringToEncrypt);
}

- (void)testKeyIsRestoredFromKeychain {

  // If
  MSEncrypter *encrypter = [[MSEncrypter alloc] initWitKeyTag:kMSEncryptionKeyTagOriginal];
  NSString *stringToEncrypt = @"Test string";

  // When
  NSString *encrypted = [encrypter encryptString:stringToEncrypt];

  // Then
  XCTAssertNotEqualObjects(encrypted, stringToEncrypt);

  // When
  MSEncrypter *newEncrypter = [[MSEncrypter alloc] initWitKeyTag:kMSEncryptionKeyTagOriginal];
  NSString *decrypted = [newEncrypter decryptString:encrypted];

  // Then
  XCTAssertEqualObjects(decrypted, stringToEncrypt);
}

- (void)testKeyIsNull {

  // If
  [MSEncrypter deleteKeyWithTag:kMSEncryptionKeyTagOriginal];
  id encrypterMock = OCMClassMock([MSEncrypter class]);
  OCMStub([encrypterMock generateKeyWithTag:[OCMArg any]]).andReturn(nil);
  MSEncrypter *encrypter = [[MSEncrypter alloc] initWitKeyTag:kMSEncryptionKeyTagOriginal];
  NSString *stringToEncrypt = @"Test string";

  // When
  NSString *encrypted = [encrypter encryptString:stringToEncrypt];

  // Then
  XCTAssertNil(encrypted);
}

- (void)testPassingInEmptyString {

  // If
  MSEncrypter *encrypter = [[MSEncrypter alloc] initWitKeyTag:kMSEncryptionKeyTagOriginal];
  NSString *expected = @"";
  NSString *emptyString = @"";

  // When
  NSString *decryptedString = [encrypter decryptString:emptyString];

  // Then
  XCTAssertEqualObjects(expected, decryptedString);
}

- (void)testEncryptWithCurrentKey {

  // If
  NSString *clearText = @"clear text";

  // Save metadata to user defaults.
  MSMockUserDefaults *mockUserDefaults = [[MSMockUserDefaults alloc] init];
  NSDate *expiration = [NSDate dateWithTimeIntervalSinceNow:10000000];
  NSString *expirationIso = [MSUtility dateToISO8601:expiration];
  NSString *keyId = kMSEncryptionKeyTagAlternate;
  NSString *keyMetadataString = [NSString stringWithFormat:@"%@:%@", keyId, expirationIso];
  [mockUserDefaults setObject:keyMetadataString forKey:kMSEncryptionKeyMetadataKey];

  // Save key to the Keychain.
  NSString *currentKey = [self generateTestEncryptionKey];
  [self.keychainUtilMock setObject:currentKey forKey:keyId];
  MSEncrypter *encrypter = [[MSEncrypter alloc] init];

  // When
  NSString *encryptedString = [encrypter encryptString:clearText];

  // Then

  // Extract metadata
  NSData *encryptedData = [[NSData alloc] initWithBase64EncodedString:encryptedString options:0];
  NSString *utf8Cipher = [[NSString alloc] initWithData:encryptedData encoding:NSUTF8StringEncoding];
  size_t metadataLength = [utf8Cipher rangeOfString:kMSEncryptionMetadataSeparator].location;
  NSString *metadata = [utf8Cipher substringToIndex:(metadataLength - 1)];
  NSString *cipherTextAndIv = [utf8Cipher substringFromIndex:(metadataLength + 1)];
  NSString *cipherText = [cipherTextAndIv substringFromIndex:kCCBlockSizeAES128];
  XCTAssertNotEqualObjects(cipherText, clearText);
  XCTAssertEqualObjects(metadata, @"kMSEncryptionKeyTagAlternate/AES/CBC/PKCS7/256");
}

- (void)testDecryptionWithWrongInitializationVectorFails {

  // If
  //1. Mock user defaults so that it contains the id+expiration
  //2. Mock keychain utils so that it contains legacy key + the key for the id in defaults
  NSString *clearText = @"clear text";

  // When
  // 1. encrypt string is called
  // 2. change iv secrion of cipher returned
  // 3. decrypt cipher text

  // Then
  // 1. Result should not equal clear text
}

- (void)testKeyRotatedOnFirstRun {

  // If
  NSString *clearText = @"clear text";

  // When
  // 1. encrypt string is called

  // Then
  //1. Assert that cipher text is not equal to clear text
  //2. Check metadata on cipher text
  //3. User defaults contains id/expiration
  //4. key is added to keychain
}

- (void)testDecryptLegacyItem {

  // If
  //1. Create item that is encrypted without metadata using legacy key

  // When
  //1. Decrypt item

  // Then
  //1. Verify cipher == clear
}

- (void)testDecryptWithExpiredKey {

  // If
  //1. Mock user defaults so that it contains the id+expiration
  //2. Mock keychain utils so that it contains legacy key + the key for the id in defaults
  //3. Mock keychain utils to contain a key with a different tag
  NSString *clearText = @"clear text";
  //4. encrypt item using the expired key

  // When
  //1. decrypt the item

  // Then
  //1. Verify cipher == clear
}

- (void)testEncryptRotatesKeyWhenExpired {
  // If
  //1. Mock user defaults so that it contains the id+expiration (expiration is expired)
  //2. Mock keychain utils so that it contains legacy key + the key for the id in defaults
  NSString *clearText = @"clear text";

  // When
  //1. encrypt item

  // Then
  //1. Assert that cipher text is not equal to clear text
  //2. Check metadata on cipher text
  //3. User defaults contains new id/expiration
  //4. key is added to keychain
}

- (NSString *)generateTestEncryptionKey {
  NSData *resultKey = nil;
  uint8_t *keyBytes = nil;
  keyBytes = malloc(kMSCipherKeySize * sizeof(uint8_t));
  memset((void *)keyBytes, 0x0, kMSCipherKeySize);
  SecRandomCopyBytes(kSecRandomDefault, kMSCipherKeySize, keyBytes);
  resultKey = [[NSData alloc] initWithBytes:keyBytes length:kMSCipherKeySize];
  free(keyBytes);
  return [resultKey base64EncodedStringWithOptions:0];
}

@end
