#import "MSEncrypter.h"
#import "MSTestFrameworks.h"

@interface MSEncrypterTests : XCTestCase

@end

@implementation MSEncrypterTests

- (void)testEncryption {

  MSEncrypter *encrypter = [[MSEncrypter alloc] initWithDefaultKeyPair];
  NSString *stringToEncrypt = @"Test string";
  NSString *encrypted = [encrypter encryptString:stringToEncrypt];
  NSString *decrypted = [encrypter decryptString:encrypted];
  XCTAssertEqualObjects(decrypted, stringToEncrypt);
  
}

@end
