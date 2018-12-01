#import <CommonCrypto/CommonCryptor.h>

#import "MSAppCenterInternal.h"
#import "MSEncrypterPrivate.h"
#import "MSKeychainUtil.h"
#import "MSLogger.h"

static int const kMSEncryptionAlgorithm = kCCAlgorithmAES128;
static int const kMSCipherKeySize = kCCKeySizeAES256;
static NSString *kMSEncryptionKeyTag = @"kMSEncryptionKeyTag";

@interface MSEncrypter ()

@property(nonatomic) NSData *key;

@property(nonatomic) CCCryptorRef encryptorObject;

@property(nonatomic) CCCryptorRef decryptorObject;

@property(nonatomic) BOOL cryptorCreated;

@end

@implementation MSEncrypter

- (instancetype)initWitKeyTag:(NSString *)keyTag {
  if ((self = [super init])) {
    [self createCryptorContexts:keyTag];
  }
  return self;
}

- (void)createCryptorContexts:(NSString *)keyTag {

  // Skip if it is already created.
  if (self.cryptorCreated) {
    return;
  }

  // Load a key with keyTag.
  NSData *key = [MSEncrypter loadKeyFromKeychainWithTag:keyTag];
  if (!key) {
    key = [MSEncrypter generateKeyWithTag:keyTag];
  }

  // Set a key to the property.
  self.key = key;

  // Create Cryptorgraphics context for encryption.
  CCCryptorRef encObj;
  CCCryptorStatus encStatus =
      CCCryptorCreate(kCCEncrypt, kMSEncryptionAlgorithm, kCCOptionPKCS7Padding, [self.key bytes], kMSCipherKeySize, NULL, &encObj);
  self.encryptorObject = encObj;

  // Create Cryptorgraphics context for descryption.
  CCCryptorRef decObj;
  CCCryptorStatus decStatus =
      CCCryptorCreate(kCCDecrypt, kMSEncryptionAlgorithm, kCCOptionPKCS7Padding, [self.key bytes], kMSCipherKeySize, NULL, &decObj);
  self.decryptorObject = decObj;

  // Log if it failed to create cryptorgraphics contexts.
  if (encStatus != kCCSuccess || decStatus != kCCSuccess) {
    MSLogError([MSAppCenter logTag], @"Could not create cryptor object.");
  }
  self.cryptorCreated = YES;
}

- (void)dealloc {
  CCCryptorRelease(self.encryptorObject);
  CCCryptorRelease(self.decryptorObject);
}

- (NSString *_Nullable)encryptString:(NSString *)string {
  [self createCryptorContexts:kMSEncryptionKeyTag];
  if (!self.key) {
    MSLogError([MSAppCenter logTag], @"Could not perform encryption. Encryption key is missing.");
    return nil;
  }
  NSString *result = nil;
  NSData *dataToEncrypt = [string dataUsingEncoding:NSUTF8StringEncoding];
  size_t cipherBufferSize = CCCryptorGetOutputLength(self.encryptorObject, dataToEncrypt.length, true);
  uint8_t *cipherBuffer = malloc(cipherBufferSize * sizeof(uint8_t));
  size_t numBytesEncrypted = 0;
  CCCryptorStatus status = CCCrypt(kCCEncrypt, kMSEncryptionAlgorithm, kCCOptionPKCS7Padding, [self.key bytes], kMSCipherKeySize, nil,
                                   [dataToEncrypt bytes], dataToEncrypt.length, cipherBuffer, cipherBufferSize, &numBytesEncrypted);
  if (status != kCCSuccess) {
    MSLogError([MSAppCenter logTag], @"Error performing encryption.");
  } else {
    result = [[NSData dataWithBytes:(const void *)cipherBuffer length:(NSUInteger)numBytesEncrypted] base64EncodedStringWithOptions:0];
  }
  free(cipherBuffer);
  return result;
}

- (NSString *_Nullable)decryptString:(NSString *)string {
  [self createCryptorContexts:kMSEncryptionKeyTag];
  if (!self.key) {
    MSLogError([MSAppCenter logTag], @"Could not perform decryption. Encryption key is missing.");
    return nil;
  }
  NSString *result = nil;
  NSData *dataToDecrypt = [[NSData alloc] initWithBase64EncodedString:string options:0];
  size_t cipherBufferSize = CCCryptorGetOutputLength(self.decryptorObject, dataToDecrypt.length, true);
  uint8_t *cipherBuffer = malloc(cipherBufferSize * sizeof(uint8_t));
  size_t numBytesDecrypted = 0;
  CCCryptorStatus status = CCCrypt(kCCDecrypt, kMSEncryptionAlgorithm, kCCOptionPKCS7Padding, [self.key bytes], kMSCipherKeySize, nil,
                                   [dataToDecrypt bytes], dataToDecrypt.length, cipherBuffer, cipherBufferSize, &numBytesDecrypted);
  if (status != kCCSuccess) {
    MSLogError([MSAppCenter logTag], @"Error performing decryption.");
  } else {
    result = [[NSString alloc] initWithData:[NSData dataWithBytes:cipherBuffer length:numBytesDecrypted] encoding:NSUTF8StringEncoding];
  }
  free(cipherBuffer);
  return result;
}

+ (void)deleteKeyWithTag:(NSString *)keyTag {
  [MSKeychainUtil deleteStringForKey:keyTag];
}

+ (NSData *)loadKeyFromKeychainWithTag:(NSString *)keyTag {
  NSData *keyData = nil;
  NSString *stringKey = [MSKeychainUtil stringForKey:keyTag];
  if (stringKey) {
    keyData = [[NSData alloc] initWithBase64EncodedString:stringKey options:0];
  }
  return keyData;
}

+ (NSData *)generateKeyWithTag:(NSString *)keyTag {
  NSData *resultKey = nil;
  uint8_t *keyBytes = nil;
  keyBytes = malloc(kMSCipherKeySize * sizeof(uint8_t));
  memset((void *)keyBytes, 0x0, kMSCipherKeySize);
  OSStatus status = SecRandomCopyBytes(kSecRandomDefault, kMSCipherKeySize, keyBytes);
  if (status != errSecSuccess) {
    MSLogError([MSAppCenter logTag], @"Error generating encryption key. Error code: %d", (int)status);
  }
  resultKey = [[NSData alloc] initWithBytes:keyBytes length:kMSCipherKeySize];
  free(keyBytes);

  // Save key to the Keychain.
  NSString *stringKey = [resultKey base64EncodedStringWithOptions:0];
  [MSKeychainUtil storeString:stringKey forKey:keyTag];
  return resultKey;
}

@end
