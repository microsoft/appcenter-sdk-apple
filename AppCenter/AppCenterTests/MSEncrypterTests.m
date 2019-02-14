#import "MSEncrypterPrivate.h"
#import "MSMockKeychainUtil.h"
#import "MSTestFrameworks.h"

@interface MSEncrypterTests : XCTestCase

@property(nonatomic) NSString *keyTag;
@property(nonatomic) id keychainUtilMock;

@end

@implementation MSEncrypterTests

- (void)setUp {
  [super setUp];
  self.keychainUtilMock = [MSMockKeychainUtil new];
  self.keyTag = @"kMSTestEncryptionKeyTag";
}

- (void)tearDown {
  [self.keychainUtilMock stopMocking];
  [MSEncrypter deleteKeyWithTag:self.keyTag];
}

- (void)testEncryption {

  // If
  MSEncrypter *encrypter = [[MSEncrypter alloc] initWitKeyTag:self.keyTag];
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
  MSEncrypter *encrypter = [[MSEncrypter alloc] initWitKeyTag:self.keyTag];
  NSString *stringToEncrypt = @"Test string";

  // When
  NSString *encrypted = [encrypter encryptString:stringToEncrypt];

  // Then
  XCTAssertNotEqualObjects(encrypted, stringToEncrypt);

  // When
  MSEncrypter *newEncrypter = [[MSEncrypter alloc] initWitKeyTag:self.keyTag];
  NSString *decrypted = [newEncrypter decryptString:encrypted];

  // Then
  XCTAssertEqualObjects(decrypted, stringToEncrypt);
}

- (void)testKeyIsNull {

  // If
  id encrypterMock = OCMClassMock([MSEncrypter class]);
  OCMStub([encrypterMock generateKeyWithTag:[OCMArg any]]).andReturn(nil);
  MSEncrypter *encrypter = [[MSEncrypter alloc] initWitKeyTag:self.keyTag];
  NSString *stringToEncrypt = @"Test string";

  // When
  NSString *encrypted = [encrypter encryptString:stringToEncrypt];

  // Then
  XCTAssertNil(encrypted);
}

@end
