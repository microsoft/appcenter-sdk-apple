#import "MSEncrypter.h"

static NSString const *kMSEncryptionPrivateKeyTag = @"kMSEncryptionPrivateKeyTag";
static NSString const *kMSEncryptionPublicKeyTag = @"kMSEncryptionPublicKeyTag";

@interface MSEncrypter()

@property(nonatomic) SecKeyRef privateKey;

@property(nonatomic) SecKeyRef publicKey;

@property(nonatomic) size_t blockSize;

@end

@implementation MSEncrypter

- (instancetype)initWithDefaultKeyPair{
  SecKeyRef publicKey = NULL, privateKey = NULL;
  [MSEncrypter encryptionKeyPairFromKeychainToPublicKey:&publicKey andPrivateKey:&privateKey];
  if (!privateKey) {
    [MSEncrypter generateEncryptionKeyPairToPublicKey:&publicKey andPrivateKey:&privateKey];
  }
  return [self initWithPublicKey:publicKey andPrivateKey:privateKey];
}

- (instancetype)initWithPublicKey:(SecKeyRef)publicKey andPrivateKey:(SecKeyRef)privateKey{
  if ((self = [super init])) {
    _publicKey = publicKey;
    _privateKey = privateKey;
    _blockSize = SecKeyGetBlockSize(_publicKey);
  }
  return self;
}

- (NSString *_Nullable) encryptString:(NSString *)string {
  NSData *dataToEncrypt = [string dataUsingEncoding:NSUTF8StringEncoding];
  size_t cipherBufferSize = self.blockSize;
  uint8_t *cipherBuffer = malloc(cipherBufferSize);
  SecKeyEncrypt(self.publicKey, kSecPaddingPKCS1, (const uint8_t *)dataToEncrypt.bytes, dataToEncrypt.length, cipherBuffer, &cipherBufferSize);
  NSString *result = [[NSData dataWithBytes:(const void *)cipherBuffer length:(NSUInteger)cipherBufferSize] base64EncodedStringWithOptions:0];
  free(cipherBuffer);
  return result;
}

- (NSString *_Nullable) decryptString:(NSString *)string {
  NSData *data = [[NSData alloc] initWithBase64EncodedString:string options:0];
  size_t cipherBufferSize = self.blockSize;
  uint8_t *cipherBuffer = malloc(cipherBufferSize);
  SecKeyDecrypt(self.privateKey, kSecPaddingPKCS1, (const uint8_t *)data.bytes, data.length, cipherBuffer, &cipherBufferSize);
  NSString *result = [[NSString alloc] initWithData:[NSData dataWithBytes:(const void *)cipherBuffer length:(NSUInteger)cipherBufferSize] encoding:NSUTF8StringEncoding];
  free(cipherBuffer);
  return result;
}

- (void)dealloc{
  CFRelease(self.publicKey);
  CFRelease(self.privateKey);
}

+ (void)encryptionKeyPairFromKeychainToPublicKey:(SecKeyRef *)publicKey andPrivateKey:(SecKeyRef *)privateKey {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wcast-qual"
  NSDictionary *privateQuery = @{(id)kSecClass: (id)kSecClassKey,
                          (id)kSecAttrApplicationTag: kMSEncryptionPrivateKeyTag,
                          (id)kSecAttrKeyType: (id)kSecAttrKeyTypeRSA,
                          (id)kSecReturnRef: @YES};
  SecItemCopyMatching((__bridge CFDictionaryRef)privateQuery, (CFTypeRef *)privateKey);
  NSDictionary *publicQuery = @{(id)kSecClass: (id)kSecClassKey,
                          (id)kSecAttrApplicationTag: kMSEncryptionPublicKeyTag,
                          (id)kSecAttrKeyType: (id)kSecAttrKeyTypeRSA,
                          (id)kSecReturnRef: @YES};
  SecItemCopyMatching((__bridge CFDictionaryRef)publicQuery, (CFTypeRef *)publicKey);
#pragma clang diagnostic pop
}

+ (void)generateEncryptionKeyPairToPublicKey:(SecKeyRef *)publicKey andPrivateKey:(SecKeyRef *)privateKey {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wcast-qual"
  NSData* privateKeyTagData = [kMSEncryptionPrivateKeyTag dataUsingEncoding:NSUTF8StringEncoding];
  NSData* publicKeyTagData = [kMSEncryptionPublicKeyTag dataUsingEncoding:NSUTF8StringEncoding];
  NSDictionary* attributes =@{(id)kSecAttrKeyType: (id)kSecAttrKeyTypeRSA,
                              (id)kSecAttrKeySizeInBits: @2048,
                              (id)kSecPrivateKeyAttrs:
                                @{(id)kSecAttrIsPermanent:@YES,
                                  (id)kSecAttrApplicationTag: privateKeyTagData},
                              (id)kSecPublicKeyAttrs:
                                @{(id)kSecAttrIsPermanent:@YES,
                                  (id)kSecAttrApplicationTag: publicKeyTagData}};
  SecKeyGeneratePair((__bridge CFDictionaryRef)attributes, publicKey, privateKey);
#pragma clang diagnostic pop
}
@end
