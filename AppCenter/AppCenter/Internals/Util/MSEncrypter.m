#import "MSAppCenterInternal.h"
#import "MSEncrypter.h"
#import "MSLogger.h"

static NSString const *kMSEncryptionPrivateKeyTag = @"kMSEncryptionPrivateKeyTag";
static NSString const *kMSEncryptionPublicKeyTag = @"kMSEncryptionPublicKeyTag";

@interface MSEncrypter()

@property(nonatomic) SecKeyRef privateKey;

@property(nonatomic) SecKeyRef publicKey;

@property(nonatomic) size_t blockSize;

@end

@implementation MSEncrypter

- (instancetype)initWithDefaultKeyPair {
  SecKeyRef publicKey = nil, privateKey = nil;
  [MSEncrypter loadKeyPairFromKeychainToPublicKey:&publicKey andPrivateKey:&privateKey];
  if (!privateKey) {
    [MSEncrypter generateKeyPairToPublicKey:&publicKey andPrivateKey:&privateKey];
  }
  if (publicKey && privateKey) {
    self = [self initWithPublicKey:publicKey andPrivateKey:privateKey];
  }
  return self;
}

- (instancetype)initWithPublicKey:(SecKeyRef)publicKey andPrivateKey:(SecKeyRef)privateKey {
  if ((self = [super init])) {
    _publicKey = publicKey;
    _privateKey = privateKey;
    _blockSize = SecKeyGetBlockSize(_publicKey);
  }
  return self;
}

- (NSString *_Nullable) encryptString:(NSString *)string {
  if (!self.publicKey) {
    return nil;
  }
  NSString *result = nil;
  NSData *dataToEncrypt = [string dataUsingEncoding:NSUTF8StringEncoding];
  size_t cipherBufferSize = self.blockSize;
  void *cipherBuffer = malloc(cipherBufferSize);
  OSStatus status = SecKeyEncrypt(self.publicKey, kSecPaddingPKCS1, (const uint8_t *)dataToEncrypt.bytes, dataToEncrypt.length, cipherBuffer, &cipherBufferSize);
  if (status != errSecSuccess) {
    MSLogError([MSAppCenter logTag], @"Encryption failed");
  } else {
    result = [[NSData dataWithBytes:(const void *)cipherBuffer length:(NSUInteger)cipherBufferSize] base64EncodedStringWithOptions:0];
  }
  free(cipherBuffer);
  return result;
}

- (NSString *_Nullable) decryptString:(NSString *)string {
  if (!self.privateKey) {
    return nil;
  }
  NSString *result = nil;
  NSData *data = [[NSData alloc] initWithBase64EncodedString:string options:0];
  size_t cipherBufferSize = self.blockSize;
  void *cipherBuffer = malloc(cipherBufferSize);
  OSStatus status = SecKeyDecrypt(self.privateKey, kSecPaddingPKCS1, (const uint8_t *)data.bytes, data.length, cipherBuffer, &cipherBufferSize);
  if (status != errSecSuccess) {
    MSLogError([MSAppCenter logTag], @"Decryption failed");
  } else {
    result = [[NSString alloc] initWithData:[NSData dataWithBytes:(const void *)cipherBuffer length:(NSUInteger)cipherBufferSize] encoding:NSUTF8StringEncoding];
  }
  free(cipherBuffer);
  return result;
}

- (void)dealloc{
  CFRelease(self.publicKey);
  CFRelease(self.privateKey);
}

+ (void)loadKeyPairFromKeychainToPublicKey:(SecKeyRef *)publicKey andPrivateKey:(SecKeyRef *)privateKey {
  NSDictionary *privateQuery = @{(__bridge id)kSecClass: (__bridge id)kSecClassKey,
                          (__bridge id)kSecAttrApplicationTag: kMSEncryptionPrivateKeyTag,
                          (__bridge id)kSecAttrKeyType: (__bridge id)kSecAttrKeyTypeRSA,
                          (__bridge id)kSecReturnRef: @YES};
  OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)privateQuery, (CFTypeRef *)(void *)privateKey);
  if (status != errSecSuccess) {
    MSLogError([MSAppCenter logTag], @"Could not load private key from Keychain. Error code: %d", (int)status);
  } else {
    NSMutableDictionary *publicQuery = [privateQuery mutableCopy];
    publicQuery[(__bridge id)kSecAttrApplicationTag] = kMSEncryptionPublicKeyTag;
    status = SecItemCopyMatching((__bridge CFDictionaryRef)publicQuery, (CFTypeRef *)(void *)publicKey);
    if (status != errSecSuccess) {
      MSLogError([MSAppCenter logTag], @"Could not load public key from Keychain. Error code: %d", (int)status);
    }
  }
}

+ (void)generateKeyPairToPublicKey:(SecKeyRef *)publicKey andPrivateKey:(SecKeyRef *)privateKey {
  NSData* privateKeyTagData = [kMSEncryptionPrivateKeyTag dataUsingEncoding:NSUTF8StringEncoding];
  NSData* publicKeyTagData = [kMSEncryptionPublicKeyTag dataUsingEncoding:NSUTF8StringEncoding];
  NSDictionary* attributes =@{(__bridge id)kSecAttrKeyType: (__bridge id)kSecAttrKeyTypeRSA,
                              (__bridge id)kSecAttrKeySizeInBits: @2048,
                              (__bridge id)kSecPrivateKeyAttrs:
                                @{(__bridge id)kSecAttrIsPermanent:@YES,
                                  (__bridge id)kSecAttrApplicationTag: privateKeyTagData},
                              (__bridge id)kSecPublicKeyAttrs:
                                @{(__bridge id)kSecAttrIsPermanent:@YES,
                                  (__bridge id)kSecAttrApplicationTag: publicKeyTagData}};
  OSStatus status = SecKeyGeneratePair((__bridge CFDictionaryRef)attributes, publicKey, privateKey);
  if(status != errSecSuccess) {
    MSLogError([MSAppCenter logTag], @"Could not generate key pair. Error code: %d", (int)status);
  }
}
@end
