#import "MSAppCenterInternal.h"
#import "MSEncrypter.h"
#import "MSLogger.h"
#import <CommonCrypto/CommonCryptor.h>

/*
 * This enum is absent in iOS, and was copied from cssmapple.h on the Mac OS X SDK.
 */
#if !TARGET_OS_OSX
enum {
  CSSM_ALGID_NONE = 0x00000000L,
  CSSM_ALGID_VENDOR_DEFINED = CSSM_ALGID_NONE + 0x80000000L,
  CSSM_ALGID_AES
};
#endif

static int const kMSEncryptionAlgorithm = kCCAlgorithmAES128;
static int const kMSEncryptionAlgorithmID = CSSM_ALGID_AES;
static int const kMSCipherKeySize = kCCKeySizeAES256;
static NSString const *kMSEncryptionKeyTag = @"kMSEncryptionKeyTag";

@interface MSEncrypter()

@property(nonatomic) NSData *key;

@property(nonatomic) CCCryptorRef encryptorObject;

@property(nonatomic) CCCryptorRef decryptorObject;

@end

@implementation MSEncrypter

- (instancetype)initWithDefaultKey {
  NSData *defaultKey = [MSEncrypter loadKeyFromKeychain];
  if (!defaultKey) {
    defaultKey = [MSEncrypter generateKey];
  }
  if (defaultKey) {
    self = [self initWithKey:defaultKey];
  }
  return self;
}

- (instancetype)initWithKey:(NSData *)key {
  if ((self = [super init])) {
    _key = key;
    CCCryptorStatus encStatus = CCCryptorCreate(kCCEncrypt, kMSEncryptionAlgorithm, kCCOptionPKCS7Padding, [self.key bytes], kMSCipherKeySize, NULL, &_encryptorObject);
    CCCryptorStatus decStatus = CCCryptorCreate(kCCDecrypt, kMSEncryptionAlgorithm, kCCOptionPKCS7Padding, [self.key bytes], kMSCipherKeySize, NULL, &_decryptorObject);
    if (encStatus != kCCSuccess || decStatus != kCCSuccess) {
      MSLogError([MSAppCenter logTag], @"Could not create cryptor object");
    }
  }
  return self;
}

- (void)dealloc{
  CCCryptorRelease(self.encryptorObject);
  CCCryptorRelease(self.decryptorObject);
}

- (NSString *_Nullable)encryptString:(NSString *)string {
  if (!self.key) {
    return nil;
  }
  NSString *result = nil;
  NSData *dataToEncrypt = [string dataUsingEncoding:NSUTF8StringEncoding];
  size_t cipherBufferSize = CCCryptorGetOutputLength(self.encryptorObject, dataToEncrypt.length, true);
  uint8_t *cipherBuffer = malloc(cipherBufferSize * sizeof(uint8_t));
  size_t numBytesEncrypted = 0;

  CCCryptorStatus status = CCCrypt(kCCEncrypt, kMSEncryptionAlgorithm, kCCOptionPKCS7Padding, (__bridge const void *)self.key, kMSCipherKeySize,
                                   nil, [dataToEncrypt bytes], dataToEncrypt.length, cipherBuffer, cipherBufferSize, &numBytesEncrypted);
  if (status != kCCSuccess) {
    MSLogError([MSAppCenter logTag], @"Error performing encryption");
  } else {
    result = [[NSData dataWithBytes:(const void *)cipherBuffer length:(NSUInteger)numBytesEncrypted] base64EncodedStringWithOptions:0];
  }
  free(cipherBuffer);
  return result;
}

- (NSString *_Nullable)decryptString:(NSString *)string {
  if (!self.key) {
    return nil;
  }
  NSString *result = nil;
  NSData *dataToDecrypt = [[NSData alloc] initWithBase64EncodedString:string options:0];
  size_t cipherBufferSize = CCCryptorGetOutputLength(self.decryptorObject, dataToDecrypt.length, true);
  uint8_t *cipherBuffer = malloc(cipherBufferSize * sizeof(uint8_t));
  size_t numBytesDecrypted = 0;
  CCCryptorStatus status = CCCrypt(kCCDecrypt, kMSEncryptionAlgorithm, kCCOptionPKCS7Padding, (__bridge const void *)self.key, kMSCipherKeySize,
                                   nil, [dataToDecrypt bytes], dataToDecrypt.length, cipherBuffer, cipherBufferSize, &numBytesDecrypted);
  if(status != kCCSuccess) {
    MSLogError([MSAppCenter logTag], @"Error performing decryption");
  }else {
    result = [[NSString alloc] initWithData:[NSData dataWithBytes:cipherBuffer length:numBytesDecrypted] encoding:NSUTF8StringEncoding];
  }
  free(cipherBuffer);
  return result;
}

+ (NSData *)loadKeyFromKeychain {
  NSData *keyData = nil;
  NSDictionary *keyQuery = @{(__bridge id)kSecClass: (__bridge id)kSecClassKey,
                             (__bridge id)kSecAttrApplicationTag: kMSEncryptionKeyTag,
                             (__bridge id)kSecAttrKeyType: [NSNumber numberWithUnsignedInt:CSSM_ALGID_AES],
                             (__bridge id)kSecReturnData: [NSNumber numberWithBool:YES]};

  OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)keyQuery, (CFTypeRef *)(void *)&keyData);
  if (status != errSecSuccess) {
    keyData = nil;
    MSLogError([MSAppCenter logTag], @"Could not load key from Keychain. Error code: %d", (int)status);
  }
  return keyData;
}

+ (NSData *)generateKey {
  NSData *resultKey = nil;
  uint8_t *keyBytes = nil;
  NSMutableDictionary *keyQuery = [[NSMutableDictionary alloc] init];
  [keyQuery setObject:(__bridge id)kSecClassKey forKey:(__bridge id)kSecClass];
  [keyQuery setObject:kMSEncryptionKeyTag forKey:(__bridge  id)kSecAttrApplicationTag];
  [keyQuery setObject:[NSNumber numberWithUnsignedInt:kMSEncryptionAlgorithmID] forKey:(__bridge id)kSecAttrKeyType];
  [keyQuery setObject:[NSNumber numberWithUnsignedInt:(unsigned int)(kMSCipherKeySize << 3)] forKey:(__bridge id)kSecAttrKeySizeInBits];
  [keyQuery setObject:[NSNumber numberWithUnsignedInt:(unsigned int)(kMSCipherKeySize << 3)]  forKey:(__bridge id)kSecAttrEffectiveKeySize];
  [keyQuery setObject:(__bridge id)kCFBooleanTrue forKey:(__bridge id)kSecAttrCanEncrypt];
  [keyQuery setObject:(__bridge id)kCFBooleanTrue forKey:(__bridge id)kSecAttrCanDecrypt];
  keyBytes = malloc(kMSCipherKeySize * sizeof(uint8_t));
  memset((void *)keyBytes, 0x0, kMSCipherKeySize);
  OSStatus status = SecRandomCopyBytes(kSecRandomDefault, kMSCipherKeySize, keyBytes);
  if (status != errSecSuccess) {
    MSLogError([MSAppCenter logTag], @"Error generating encryption key. Error code: %d", (int)status);
  }
  resultKey = [[NSData alloc] initWithBytes:keyBytes length:kMSCipherKeySize];
  free(keyBytes);

  // Add the wrapped key data to the container dictionary.
  [keyQuery setObject:resultKey forKey:(__bridge id)kSecValueData];

  // Add key to the keychain.
  status = SecItemAdd((CFDictionaryRef) keyQuery, nil);
  if (status != errSecSuccess) {
    MSLogError([MSAppCenter logTag], @"Error adding encryption key to keychain. Error code: %d", (int)status);
  }
  return resultKey;
}
@end

