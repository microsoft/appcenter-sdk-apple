// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSConstants+Internal.h"
#import "MSEncrypterPrivate.h"
#import "MSMockKeychainUtil.h"
#import "MSMockUserDefaults.h"
#import "MSTestFrameworks.h"
#import "MSUtility+Date.h"
#import "NSData+MSAppCenter.h"

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
  [MSMockKeychainUtil clear];
}

- (void)testEncryptWithCurrentKey {

  // If
  NSString *clearText = @"clear text";
  NSString *keyTag = kMSEncryptionKeyTagAlternate;
  NSString *expectedMetadata = [NSString stringWithFormat:@"%@/AES/CBC/PKCS7/32", keyTag];

  // Save metadata to user defaults.
  MSMockUserDefaults *mockUserDefaults = [[MSMockUserDefaults alloc] init];
  NSDate *expiration = [NSDate dateWithTimeIntervalSinceNow:10000000];
  NSString *expirationIso = [MSUtility dateToISO8601:expiration];
  NSString *keyMetadataString = [NSString stringWithFormat:@"%@/%@", keyTag, expirationIso];
  [mockUserDefaults setObject:keyMetadataString forKey:kMSEncryptionKeyMetadataKey];

  // Save key to the Keychain.
  NSString *currentKey = [self generateTestEncryptionKey];
  [MSMockKeychainUtil storeString:currentKey forKey:keyTag];
  MSEncrypter *encrypter = [[MSEncrypter alloc] init];

  // When
  NSString *encryptedString = [encrypter encryptString:clearText];

  // Then

  // Extract metadata.
  NSData *encryptedData = [[NSData alloc] initWithBase64EncodedString:encryptedString options:0];
  size_t metadataLength = [encryptedData locationOfString:kMSEncryptionMetadataSeparator usingEncoding:NSUTF8StringEncoding];
  NSString *metadata = [encryptedData stringFromRange:NSMakeRange(0, metadataLength) usingEncoding:NSUTF8StringEncoding];
  XCTAssertEqualObjects(metadata, expectedMetadata);

  // Extract cipher text. Add 1 for the delimiter.
  size_t metadataAndIvLength = metadataLength + 1 + kCCBlockSizeAES128;
  NSRange cipherTextRange = NSMakeRange(metadataAndIvLength, [encryptedData length] - metadataAndIvLength);
  NSString *cipherText = [encryptedData stringFromRange:cipherTextRange usingEncoding:NSUTF8StringEncoding];
  XCTAssertNotEqualObjects(cipherText, clearText);

  // When
  NSString *decryptedString = [encrypter decryptString:encryptedString];

  // Then
  XCTAssertEqualObjects(decryptedString, clearText);
}

- (void)testKeyRotatedOnFirstRunWithLegacyKeySaved {

  // If
  NSString *clearText = @"clear text";
  NSString *expectedMetadata = [NSString stringWithFormat:@"%@/AES/CBC/PKCS7/32", kMSEncryptionKeyTagAlternate];
  MSMockUserDefaults *mockUserDefaults = [[MSMockUserDefaults alloc] init];

  // Mock NSDate to "freeze" time.
  NSTimeInterval timeSinceReferenceDate = NSDate.timeIntervalSinceReferenceDate;
  NSDate *referenceDate = [NSDate dateWithTimeIntervalSince1970:timeSinceReferenceDate];
  id nsdateMock = OCMClassMock([NSDate class]);
  OCMStub(ClassMethod([nsdateMock timeIntervalSinceReferenceDate])).andReturn(timeSinceReferenceDate);
  OCMStub(ClassMethod([nsdateMock date])).andReturn(referenceDate);
  NSDate *expectedExpirationDate = [[NSDate date] dateByAddingTimeInterval:kMSEncryptionKeyLifetimeInSeconds];
  NSString *expectedExpirationDateIso = [MSUtility dateToISO8601:expectedExpirationDate];

  // Save key to the Keychain.
  NSString *currentKey = [self generateTestEncryptionKey];
  [MSMockKeychainUtil storeString:currentKey forKey:kMSEncryptionKeyTagOriginal];
  MSEncrypter *encrypter = [[MSEncrypter alloc] init];

  // When
  NSString *encryptedString = [encrypter encryptString:clearText];

  // Then

  // Extract metadata.
  NSData *encryptedData = [[NSData alloc] initWithBase64EncodedString:encryptedString options:0];
  size_t metadataLength = [encryptedData locationOfString:kMSEncryptionMetadataSeparator usingEncoding:NSUTF8StringEncoding];
  NSString *metadata = [encryptedData stringFromRange:NSMakeRange(0, metadataLength) usingEncoding:NSUTF8StringEncoding];
  XCTAssertEqualObjects(metadata, expectedMetadata);

  // Extract cipher text. Add 1 for the delimiter.
  size_t metadataAndIvLength = metadataLength + 1 + kCCBlockSizeAES128;
  NSRange cipherTextRange = NSMakeRange(metadataAndIvLength, [encryptedData length] - metadataAndIvLength);
  NSString *cipherText = [encryptedData stringFromRange:cipherTextRange usingEncoding:NSUTF8StringEncoding];
  XCTAssertNotEqualObjects(cipherText, clearText);

  // Ensure a new key and expiration were added to the user defaults.
  NSArray *newKeyAndExpiration =
      [[mockUserDefaults objectForKey:kMSEncryptionKeyMetadataKey] componentsSeparatedByString:kMSEncryptionMetadataInternalSeparator];
  NSString *newKey = newKeyAndExpiration[0];
  XCTAssertEqualObjects(newKey, kMSEncryptionKeyTagAlternate);
  NSString *expirationIso = newKeyAndExpiration[1];
  XCTAssertEqualObjects(expirationIso, expectedExpirationDateIso);

  // When
  NSString *decryptedString = [encrypter decryptString:encryptedString];

  // Then
  XCTAssertEqualObjects(decryptedString, clearText);
}

- (void)testEncryptRotatesKeyWhenExpiredAndTwoKeysSaved {

  // If
  NSString *clearText = @"clear text";
  MSMockUserDefaults *mockUserDefaults = [[MSMockUserDefaults alloc] init];
  NSDate *pastDate = [NSDate dateWithTimeIntervalSince1970:0];
  NSString *currentExpirationIso = [MSUtility dateToISO8601:pastDate];
  NSString *currentKeyTag = kMSEncryptionKeyTagOriginal;
  NSString *expectedNewKeyTag = kMSEncryptionKeyTagAlternate;
  NSString *currentKeyMetadataString = [NSString stringWithFormat:@"%@/%@", currentKeyTag, currentExpirationIso];
  [mockUserDefaults setObject:currentKeyMetadataString forKey:kMSEncryptionKeyMetadataKey];
  NSString *expectedMetadata = [NSString stringWithFormat:@"%@/AES/CBC/PKCS7/32", expectedNewKeyTag];

  // Mock NSDate to "freeze" time.
  NSTimeInterval timeSinceReferenceDate = NSDate.timeIntervalSinceReferenceDate;
  NSDate *referenceDate = [NSDate dateWithTimeIntervalSince1970:timeSinceReferenceDate];
  id nsdateMock = OCMClassMock([NSDate class]);
  OCMStub(ClassMethod([nsdateMock timeIntervalSinceReferenceDate])).andReturn(timeSinceReferenceDate);
  OCMStub(ClassMethod([nsdateMock date])).andReturn(referenceDate);
  NSDate *expectedExpirationDate = [[NSDate date] dateByAddingTimeInterval:kMSEncryptionKeyLifetimeInSeconds];
  NSString *expectedExpirationDateIso = [MSUtility dateToISO8601:expectedExpirationDate];

  // Save both keys to the Keychain.
  NSString *currentKey = [self generateTestEncryptionKey];
  [MSMockKeychainUtil storeString:currentKey forKey:currentKeyTag];
  NSString *expectedNewKey = [self generateTestEncryptionKey];
  [MSMockKeychainUtil storeString:expectedNewKey forKey:expectedNewKeyTag];
  MSEncrypter *encrypter = [[MSEncrypter alloc] init];

  // When
  NSString *encryptedString = [encrypter encryptString:clearText];

  // Then

  // Extract metadata.
  NSData *encryptedData = [[NSData alloc] initWithBase64EncodedString:encryptedString options:0];
  size_t metadataLength = [encryptedData locationOfString:kMSEncryptionMetadataSeparator usingEncoding:NSUTF8StringEncoding];
  NSString *metadata = [encryptedData stringFromRange:NSMakeRange(0, metadataLength) usingEncoding:NSUTF8StringEncoding];
  XCTAssertEqualObjects(metadata, expectedMetadata);

  // Extract cipher text. Add 1 for the delimiter.
  size_t metadataAndIvLength = metadataLength + 1 + kCCBlockSizeAES128;
  NSRange cipherTextRange = NSMakeRange(metadataAndIvLength, [encryptedData length] - metadataAndIvLength);
  NSString *cipherText = [encryptedData stringFromRange:cipherTextRange usingEncoding:NSUTF8StringEncoding];
  XCTAssertNotEqualObjects(cipherText, clearText);

  // Ensure a new key and expiration were added to the user defaults.
  NSArray *newKeyTagAndExpiration =
      [[mockUserDefaults objectForKey:kMSEncryptionKeyMetadataKey] componentsSeparatedByString:kMSEncryptionMetadataInternalSeparator];
  NSString *newKeyTag = newKeyTagAndExpiration[0];
  XCTAssertEqualObjects(newKeyTag, expectedNewKeyTag);
  NSString *expirationIso = newKeyTagAndExpiration[1];
  XCTAssertEqualObjects(expirationIso, expectedExpirationDateIso);

  // When
  NSString *decryptedString = [encrypter decryptString:encryptedString];

  // Then
  XCTAssertEqualObjects(decryptedString, clearText);
}

- (void)testEncryptRotatesAndCreatesKeyWhenOnlyKeyIsExpired {

  // If
  NSString *clearText = @"clear text";
  MSMockUserDefaults *mockUserDefaults = [[MSMockUserDefaults alloc] init];
  NSDate *pastDate = [NSDate dateWithTimeIntervalSince1970:0];
  NSString *oldExpirationIso = [MSUtility dateToISO8601:pastDate];
  NSString *oldKey = kMSEncryptionKeyTagOriginal;
  NSString *expectedNewKeyTag = kMSEncryptionKeyTagAlternate;
  NSString *keyMetadataString = [NSString stringWithFormat:@"%@/%@", oldKey, oldExpirationIso];
  [mockUserDefaults setObject:keyMetadataString forKey:kMSEncryptionKeyMetadataKey];
  NSString *expectedMetadata = [NSString stringWithFormat:@"%@/AES/CBC/PKCS7/32", expectedNewKeyTag];

  // Mock NSDate to "freeze" time.
  NSTimeInterval timeSinceReferenceDate = NSDate.timeIntervalSinceReferenceDate;
  NSDate *referenceDate = [NSDate dateWithTimeIntervalSince1970:timeSinceReferenceDate];
  id nsdateMock = OCMClassMock([NSDate class]);
  OCMStub(ClassMethod([nsdateMock timeIntervalSinceReferenceDate])).andReturn(timeSinceReferenceDate);
  OCMStub(ClassMethod([nsdateMock date])).andReturn(referenceDate);
  NSDate *expectedExpirationDate = [[NSDate date] dateByAddingTimeInterval:kMSEncryptionKeyLifetimeInSeconds];
  NSString *expectedExpirationDateIso = [MSUtility dateToISO8601:expectedExpirationDate];

  // Save key to the Keychain.
  NSString *currentKey = [self generateTestEncryptionKey];
  [MSMockKeychainUtil storeString:currentKey forKey:oldKey];
  MSEncrypter *encrypter = [[MSEncrypter alloc] init];

  // When
  NSString *encryptedString = [encrypter encryptString:clearText];

  // Then

  // Extract metadata.
  NSData *encryptedData = [[NSData alloc] initWithBase64EncodedString:encryptedString options:0];
  size_t metadataLength = [encryptedData locationOfString:kMSEncryptionMetadataSeparator usingEncoding:NSUTF8StringEncoding];
  NSString *metadata = [encryptedData stringFromRange:NSMakeRange(0, metadataLength) usingEncoding:NSUTF8StringEncoding];
  XCTAssertEqualObjects(metadata, expectedMetadata);

  // Extract cipher text. Add 1 for the delimiter.
  size_t metadataAndIvLength = metadataLength + 1 + kCCBlockSizeAES128;
  NSRange cipherTextRange = NSMakeRange(metadataAndIvLength, [encryptedData length] - metadataAndIvLength);
  NSString *cipherText = [encryptedData stringFromRange:cipherTextRange usingEncoding:NSUTF8StringEncoding];
  XCTAssertNotEqualObjects(cipherText, clearText);

  // Ensure a new key and expiration were added to the user defaults.
  NSArray *newKeyAndExpiration =
      [[mockUserDefaults objectForKey:kMSEncryptionKeyMetadataKey] componentsSeparatedByString:kMSEncryptionMetadataInternalSeparator];
  NSString *newKey = newKeyAndExpiration[0];
  XCTAssertEqualObjects(newKey, expectedNewKeyTag);
  NSString *expirationIso = newKeyAndExpiration[1];
  XCTAssertEqualObjects(expirationIso, expectedExpirationDateIso);

  // When
  NSString *decryptedString = [encrypter decryptString:encryptedString];

  // Then
  XCTAssertEqualObjects(decryptedString, clearText);
}

- (void)testDecryptLegacyItem {

  // If
  NSString *clearText = @"Test string";

  // Save the key to disk. This must not change as it was used to encrypt the text.
  NSString *currentKey = @"zlIS50zXq7fm2GqassShXrjkMBsdjlTsmIT+d1D3CTI=";
  [MSMockKeychainUtil storeString:currentKey forKey:kMSEncryptionKeyTagOriginal];

  // This cipher text contains no metadata, and no IV was used.
  NSString *cipherText = @"S6uNmq7u0eKGaU2GQPUGMQ==";
  MSEncrypter *encrypter = [[MSEncrypter alloc] init];

  // When
  NSString *decryptedString = [encrypter decryptString:cipherText];

  // Then
  XCTAssertEqualObjects(decryptedString, clearText);
}

- (void)testEncryptionCreatesKeyWhenNoKeyIsSaved {

  // If
  NSString *clearText = @"clear text";
  NSString *expectedMetadata = [NSString stringWithFormat:@"%@/AES/CBC/PKCS7/32", kMSEncryptionKeyTagAlternate];
  MSMockUserDefaults *mockUserDefaults = [[MSMockUserDefaults alloc] init];

  // Mock NSDate to "freeze" time.
  NSTimeInterval timeSinceReferenceDate = NSDate.timeIntervalSinceReferenceDate;
  NSDate *referenceDate = [NSDate dateWithTimeIntervalSince1970:timeSinceReferenceDate];
  id nsdateMock = OCMClassMock([NSDate class]);
  OCMStub(ClassMethod([nsdateMock timeIntervalSinceReferenceDate])).andReturn(timeSinceReferenceDate);
  OCMStub(ClassMethod([nsdateMock date])).andReturn(referenceDate);
  NSDate *expectedExpirationDate = [[NSDate date] dateByAddingTimeInterval:kMSEncryptionKeyLifetimeInSeconds];
  NSString *expectedExpirationDateIso = [MSUtility dateToISO8601:expectedExpirationDate];
  MSEncrypter *encrypter = [[MSEncrypter alloc] init];

  // When
  NSString *encryptedString = [encrypter encryptString:clearText];

  // Then

  // Extract metadata.
  NSData *encryptedData = [[NSData alloc] initWithBase64EncodedString:encryptedString options:0];
  size_t metadataLength = [encryptedData locationOfString:kMSEncryptionMetadataSeparator usingEncoding:NSUTF8StringEncoding];
  NSString *metadata = [encryptedData stringFromRange:NSMakeRange(0, metadataLength) usingEncoding:NSUTF8StringEncoding];
  XCTAssertEqualObjects(metadata, expectedMetadata);

  // Extract cipher text. Add 1 for the delimiter.
  size_t metadataAndIvLength = metadataLength + 1 + kCCBlockSizeAES128;
  NSRange cipherTextRange = NSMakeRange(metadataAndIvLength, [encryptedData length] - metadataAndIvLength);
  NSString *cipherText = [encryptedData stringFromRange:cipherTextRange usingEncoding:NSUTF8StringEncoding];
  XCTAssertNotEqualObjects(cipherText, clearText);

  // Ensure a new key and expiration were added to the user defaults.
  NSArray *newKeyAndExpiration =
      [[mockUserDefaults objectForKey:kMSEncryptionKeyMetadataKey] componentsSeparatedByString:kMSEncryptionMetadataInternalSeparator];
  NSString *newKey = newKeyAndExpiration[0];
  XCTAssertEqualObjects(newKey, kMSEncryptionKeyTagAlternate);
  NSString *expirationIso = newKeyAndExpiration[1];
  XCTAssertEqualObjects(expirationIso, expectedExpirationDateIso);

  // When
  NSString *decryptedString = [encrypter decryptString:encryptedString];

  // Then
  XCTAssertEqualObjects(decryptedString, clearText);
}

- (void)testDecryptWithExpiredKey {

  // If
  NSString *clearText = @"clear text";
  MSMockUserDefaults *mockUserDefaults = [[MSMockUserDefaults alloc] init];

  // Save metadata to user defaults.
  NSDate *expiration = [NSDate dateWithTimeIntervalSinceNow:10000000];
  NSString *keyId = kMSEncryptionKeyTagOriginal;
  NSString *expirationIso = [MSUtility dateToISO8601:expiration];
  NSString *keyMetadataString = [NSString stringWithFormat:@"%@/%@", keyId, expirationIso];
  [mockUserDefaults setObject:keyMetadataString forKey:kMSEncryptionKeyMetadataKey];

  // Save key to the Keychain.
  NSString *currentKey = [self generateTestEncryptionKey];
  [MSMockKeychainUtil storeString:currentKey forKey:keyId];
  MSEncrypter *encrypter = [[MSEncrypter alloc] init];

  // When
  NSString *encryptedString = [encrypter encryptString:clearText];

  // Alter the expiration date of the key so that it is now expired.
  NSDate *pastDate = [NSDate dateWithTimeIntervalSinceNow:-1000000];
  NSString *oldExpirationIso = [MSUtility dateToISO8601:pastDate];
  NSString *alteredKeyMetadataString = [NSString stringWithFormat:@"%@/%@", keyId, oldExpirationIso];
  [mockUserDefaults setObject:alteredKeyMetadataString forKey:kMSEncryptionKeyMetadataKey];

  // When
  NSString *decryptedString = [encrypter decryptString:encryptedString];

  // Then
  XCTAssertEqualObjects(decryptedString, clearText);
}

- (void)testEncryptWithCurrentKeyWithEmptyClearText {

  // If
  NSString *clearText = @"";
  NSString *keyTag = kMSEncryptionKeyTagAlternate;
  NSString *expectedMetadata = [NSString stringWithFormat:@"%@/AES/CBC/PKCS7/32", keyTag];

  // Save metadata to user defaults.
  MSMockUserDefaults *mockUserDefaults = [[MSMockUserDefaults alloc] init];
  NSDate *expiration = [NSDate dateWithTimeIntervalSinceNow:10000000];
  NSString *expirationIso = [MSUtility dateToISO8601:expiration];
  NSString *keyMetadataString = [NSString stringWithFormat:@"%@/%@", keyTag, expirationIso];
  [mockUserDefaults setObject:keyMetadataString forKey:kMSEncryptionKeyMetadataKey];

  // Save key to the Keychain.
  NSString *currentKey = [self generateTestEncryptionKey];
  [MSMockKeychainUtil storeString:currentKey forKey:keyTag];
  MSEncrypter *encrypter = [[MSEncrypter alloc] init];

  // When
  NSString *encryptedString = [encrypter encryptString:clearText];

  // Then

  // Extract metadata.
  NSData *encryptedData = [[NSData alloc] initWithBase64EncodedString:encryptedString options:0];
  size_t metadataLength = [encryptedData locationOfString:kMSEncryptionMetadataSeparator usingEncoding:NSUTF8StringEncoding];
  NSString *metadata = [encryptedData stringFromRange:NSMakeRange(0, metadataLength) usingEncoding:NSUTF8StringEncoding];
  XCTAssertEqualObjects(metadata, expectedMetadata);

  // Extract cipher text. Add 1 for the delimiter.
  size_t metadataAndIvLength = metadataLength + 1 + kCCBlockSizeAES128;
  NSRange cipherTextRange = NSMakeRange(metadataAndIvLength, [encryptedData length] - metadataAndIvLength);
  NSString *cipherText = [encryptedData stringFromRange:cipherTextRange usingEncoding:NSUTF8StringEncoding];
  XCTAssertNotEqualObjects(cipherText, clearText);

  // When
  NSString *decryptedString = [encrypter decryptString:encryptedString];

  // Then
  XCTAssertEqualObjects(decryptedString, clearText);
}

- (NSString *)generateTestEncryptionKey {
  NSData *resultKey = nil;
  uint8_t *keyBytes = nil;
  keyBytes = malloc(kMSEncryptionKeySize * sizeof(uint8_t));
  memset((void *)keyBytes, 0x0, kMSEncryptionKeySize);
  int result = SecRandomCopyBytes(kSecRandomDefault, kMSEncryptionKeySize, keyBytes);
  if (result != errSecSuccess) {
    return nil;
  }
  resultKey = [[NSData alloc] initWithBytes:keyBytes length:kMSEncryptionKeySize];
  free(keyBytes);
  return [resultKey base64EncodedStringWithOptions:0];
}

@end
