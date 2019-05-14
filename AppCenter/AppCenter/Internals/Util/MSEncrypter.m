// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <CommonCrypto/CommonCryptor.h>

#import "MSAppCenterInternal.h"
#import "MSConstants+Internal.h"
#import "MSEncrypterPrivate.h"
#import "MSKeychainUtil.h"
#import "MSLogger.h"

static NSObject *const classLock;

@interface MSEncrypter ()

@property(nonatomic) NSMutableDictionary *keys;

@end

@implementation MSEncrypter

- (instancetype)init {
  if ((self = [super init])) {
    _keys = [NSMutableDictionary new];
  }
  return self;
}

- (NSString *_Nullable)encryptString:(NSString *)string {
  NSData *dataToEncrypt = [string dataUsingEncoding:NSUTF8StringEncoding];
  NSData *encryptedData = [self encryptData:dataToEncrypt];
  return [encryptedData base64EncodedStringWithOptions:0];
}

- (NSData *_Nullable)encryptData:(NSData *)data {
  NSString *keyTag = [[self class] getCurrentKeyTag];
  NSData *key = [self getKeyWithKeyTag:keyTag];
  NSData *initializationVector = [[self class] generateInitializationVector];
  NSData *result = [[self class] performCryptoOperation:kCCEncrypt input:data initializationVector:initializationVector key:key];
  if (result) {
    NSData *metadata = [[self class] getMetadataStringWithKeyTag:keyTag];
    NSMutableData *mutableData = [NSMutableData new];
    [mutableData appendData:metadata];
    [mutableData appendBytes:(const void *)[kMSEncryptionMetadataSeparator UTF8String] length:1];
    [mutableData appendData:initializationVector];
    [mutableData appendData:result];
    result = mutableData;
  }
  return result;
}

- (NSString *_Nullable)decryptString:(NSString *)string {
  NSString *result = nil;
  NSData *dataToDecrypt = [[NSData alloc] initWithBase64EncodedString:string options:0];
  if (dataToDecrypt) {
    NSData *decryptedBytes = [self decryptData:dataToDecrypt];
    result = [[NSString alloc] initWithData:decryptedBytes encoding:NSUTF8StringEncoding];
    if (!result) {
      MSLogWarning([MSAppCenter logTag], @"Converting decrypted NSData to NSString failed.");
    }
  } else {
    MSLogWarning([MSAppCenter logTag], @"Conversion of encrypted string to NSData failed.");
  }
  return result;
}

- (NSData *_Nullable)decryptData:(NSData *)data {

  // Separate cipher prefix from cipher.
  NSRange dataRange = NSMakeRange(0, [data length]);
  NSData *separatorAsData = [kMSEncryptionMetadataSeparator dataUsingEncoding:NSUTF8StringEncoding];
  size_t metadataLocation = [data rangeOfData:separatorAsData options:0 range:dataRange].location;
  NSString *metadata;
  if (metadataLocation != NSNotFound) {
    NSData *subdata = [data subdataWithRange:NSMakeRange(0, metadataLocation)];
    metadata = [[NSString alloc] initWithData:subdata encoding:NSUTF8StringEncoding];
  }
  NSData *key;
  NSData *initializationVector;
  NSData *cipherText;
  if (!metadata) {

    // If there is no metadata, this is old data, so use the old key and an empty initialization vector.
    key = [self getKeyWithKeyTag:kMSEncryptionKeyTagOriginal];
    initializationVector = nil;
    cipherText = data;
  } else {

    // Extract key from metadata.
    NSString *keyTag = [metadata componentsSeparatedByString:kMSEncryptionMetadataInternalSeparator][0];
    NSRange ivRange = NSMakeRange(metadataLocation + 1, kCCBlockSizeAES128);

    // Metadata, separator, and initialization vector.
    size_t cipherTextPrefixLength = metadataLocation + 1 + kCCBlockSizeAES128;
    NSRange cipherTextRange = NSMakeRange(cipherTextPrefixLength, [data length] - cipherTextPrefixLength);
    initializationVector = [data subdataWithRange:ivRange];
    cipherText = [data subdataWithRange:cipherTextRange];
    key = [self getKeyWithKeyTag:keyTag];
  }
  return [[self class] performCryptoOperation:kCCDecrypt input:cipherText initializationVector:initializationVector key:key];
}

+ (NSString *)getCurrentKeyTag {
  @synchronized(classLock) {
    NSString *keyMetadata = [[MSUserDefaults shared] objectForKey:kMSEncryptionKeyMetadataKey];
    if (!keyMetadata) {
      [self rotateToNewKeyTag:kMSEncryptionKeyTagAlternate];
      return kMSEncryptionKeyTagAlternate;
    }

    // Format is {keyTag}/{expiration as iso}
    NSArray *keyMetadataComponents = [keyMetadata componentsSeparatedByString:kMSEncryptionMetadataInternalSeparator];
    NSString *keyTag = keyMetadataComponents[0];
    NSString *expirationIso = keyMetadataComponents[1];
    NSDate *expiration = [MSUtility dateFromISO8601:expirationIso];
    BOOL isNotExpired = [[expiration laterDate:[NSDate date]] isEqualToDate:expiration];
    if (isNotExpired) {
      return keyTag;
    }

    // Key is expired and must be rotated.
    if ([keyTag isEqualToString:kMSEncryptionKeyTagOriginal]) {
      keyTag = kMSEncryptionKeyTagAlternate;
    } else {
      keyTag = kMSEncryptionKeyTagOriginal;
    }
    [self rotateToNewKeyTag:keyTag];
    return keyTag;
  }
}

+ (void)rotateToNewKeyTag:(NSString *)newKeyTag {
  NSDate *expiration = [[NSDate date] dateByAddingTimeInterval:kMSEncryptionKeyLifetimeInSeconds];
  NSString *expirationIso = [MSUtility dateToISO8601:expiration];

  // Format is {keyTag}/{expiration as iso}
  NSString *keyMetadata = [@[ newKeyTag, expirationIso ] componentsJoinedByString:kMSEncryptionMetadataInternalSeparator];
  [[MSUserDefaults shared] setObject:keyMetadata forKey:kMSEncryptionKeyMetadataKey];
}

- (NSData *)getKeyWithKeyTag:(NSString *)keyTag {
  NSData *key;
  @synchronized(self) {

    // Read inside of a synchronized block because NSDictionary is not thread safe.
    key = [self.keys objectForKey:keyTag];
  }

  // If key is not cached, try loading it from Keychain.
  if (!key) {
    NSString *stringKey = [MSKeychainUtil stringForKey:keyTag];

    // If key is not saved in Keychain, create one and save it.
    if (!stringKey) {
      @synchronized(classLock) {

        // Recheck if the key has been written from another thread.
        stringKey = [MSKeychainUtil stringForKey:keyTag];
        if (!stringKey) {
          key = [[self class] generateAndSaveKeyWithTag:keyTag];
        }
      }
    } else {
      key = [[NSData alloc] initWithBase64EncodedString:stringKey options:0];
    }
    @synchronized(self) {

      // Write inside of a synchronized block because NSDictionary is not thread safe.
      [self.keys setObject:key forKey:keyTag];
    }
  }
  return key;
}

+ (NSData *_Nullable)performCryptoOperation:(CCOperation)operation
                                      input:(NSData *)input
                       initializationVector:(NSData *)initializationVector
                                        key:(NSData *)key {
  NSData *result;

  // Create a buffer whose size is at least one block plus 1. This is not needed for decryption, but it works.
  size_t outputBufferSize = [input length] + kCCBlockSizeAES128 + 1;
  uint8_t *outputBuffer = malloc(outputBufferSize * sizeof(uint8_t));
  size_t numBytesNeeded = 0;
  CCCryptorStatus status =
      CCCrypt(operation, kMSEncryptionAlgorithm, kCCOptionPKCS7Padding, [key bytes], kMSEncryptionKeySize, [initializationVector bytes],
              [input bytes], input.length, outputBuffer, outputBufferSize, &numBytesNeeded);
  if (status != kCCSuccess) {

    // Do not print the status; it is a security requirement that specific crypto errors are not printed.
    MSLogError([MSAppCenter logTag], @"Error performing encryption or decryption.");
  } else {
    result = [NSData dataWithBytes:outputBuffer length:numBytesNeeded];
    if (!result) {
      MSLogWarning([MSAppCenter logTag], @"Could not create NSData object from encrypted or decrypted bytes.");
    }
  }
  free(outputBuffer);
  return result;
}

+ (NSData *)generateAndSaveKeyWithTag:(NSString *)keyTag {
  NSData *resultKey = nil;
  uint8_t *keyBytes = nil;
  keyBytes = malloc(kMSEncryptionKeySize * sizeof(uint8_t));
  memset((void *)keyBytes, 0x0, kMSEncryptionKeySize);
  OSStatus status = SecRandomCopyBytes(kSecRandomDefault, kMSEncryptionKeySize, keyBytes);
  if (status != errSecSuccess) {
    MSLogError([MSAppCenter logTag], @"Error generating encryption key. Error code: %d", (int)status);
  }
  resultKey = [[NSData alloc] initWithBytes:keyBytes length:kMSEncryptionKeySize];
  free(keyBytes);

  // Save key to the Keychain.
  NSString *stringKey = [resultKey base64EncodedStringWithOptions:0];
  [MSKeychainUtil storeString:stringKey forKey:keyTag];
  return resultKey;
}

+ (NSData *)generateInitializationVector {
  uint8_t *ivBytes = malloc(kCCBlockSizeAES128 * sizeof(uint8_t));
  memset((void *)ivBytes, 0x0, kCCBlockSizeAES128);
  OSStatus status = SecRandomCopyBytes(kSecRandomDefault, kCCBlockSizeAES128, ivBytes);
  if (status != errSecSuccess) {
    MSLogError([MSAppCenter logTag], @"Error generating initialization vector. Error code: %d", (int)status);
  }
  return [NSData dataWithBytes:ivBytes length:kCCBlockSizeAES128];
}

+ (NSData *)getMetadataStringWithKeyTag:(NSString *)keyTag {

  // Format is {key tag}/{algorithm}/{cipher mode}/{padding mode}/{key length}
  NSArray *metadata = @[ keyTag, kMSEncryptionAlgorithmName, kMSEncryptionCipherMode, kMSEncryptionPaddingMode, @(kMSEncryptionKeySize) ];
  NSString *metadataString = [metadata componentsJoinedByString:kMSEncryptionMetadataInternalSeparator];
  return [metadataString dataUsingEncoding:NSUTF8StringEncoding];
}

@end
