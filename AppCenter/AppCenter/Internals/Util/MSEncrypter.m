// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <CommonCrypto/CommonCryptor.h>

#import "MSAppCenterInternal.h"
#import "MSConstants+Internal.h"
#import "MSEncrypterPrivate.h"
#import "MSKeychainUtil.h"
#import "MSLogger.h"
#import "NSData+MSAppCenter.h"

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
  NSString *keyTag = [self getCurrentKeyTag];
  NSData *key = [self getKeyWithKeyTag:keyTag];
  NSData *result = nil;
  void *initializationVector = [[self class] generateInitializationVector];

  // TODO - buffer length and length error handling
  size_t cipherBufferSize = [data length] * 20;
  uint8_t *cipherBuffer = malloc(cipherBufferSize * sizeof(uint8_t));
  size_t numBytesEncrypted = 0;
  CCCryptorStatus status = CCCrypt(kCCEncrypt, kMSEncryptionAlgorithm, kCCOptionPKCS7Padding, [key bytes], kMSEncryptionKeySize,
                                   initializationVector, [data bytes], data.length, cipherBuffer, cipherBufferSize, &numBytesEncrypted);
  if (status != kCCSuccess) {
    MSLogError([MSAppCenter logTag], @"Error performing encryption.");
  } else {
    NSData *metadata = [[self class] getMetadataStringWithKeyTag:keyTag];
    NSMutableData *mutableData = [NSMutableData new];
    [mutableData appendData:metadata];
    [mutableData appendBytes:(const void *)[kMSEncryptionMetadataSeparator UTF8String] length:1];
    [mutableData appendBytes:initializationVector length:kCCBlockSizeAES128];
    [mutableData appendBytes:cipherBuffer length:numBytesEncrypted];
    result = mutableData;
  }
  free(cipherBuffer);
  free(initializationVector);
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

  // Extract key from metadata.
  size_t metadataLength = [data locationOfString:kMSEncryptionMetadataSeparator usingEncoding:NSUTF8StringEncoding];
  NSString *metadata = [data stringFromRange:NSMakeRange(0, metadataLength) usingEncoding:NSUTF8StringEncoding];
  if (!metadata) {
    return nil; //TODO implement legacy code path.
  }
  NSData *result = nil;
  NSString *keyTag = [metadata componentsSeparatedByString:kMSEncryptionMetadataInternalSeparator][0];
  NSRange ivRange = NSMakeRange(metadataLength + 1, kCCBlockSizeAES128);
  NSRange cipherTextRange = NSMakeRange(metadataLength + 1 + kCCBlockSizeAES128, [data length] - metadataLength - 1 - kCCBlockSizeAES128);
  NSData *initializationVector = [data subdataWithRange:ivRange];
  NSData *cipherText = [data subdataWithRange:cipherTextRange];
  NSData *key = [self getKeyWithKeyTag:keyTag];

  // TODO - buffer length and length error handling
  size_t clearTextBufferSize = [data length]*20;
  uint8_t *clearTextBuffer = malloc(clearTextBufferSize * sizeof(uint8_t));
  size_t numBytesDecrypted = 0;
  CCCryptorStatus status = CCCrypt(kCCDecrypt, kMSEncryptionAlgorithm, kCCOptionPKCS7Padding, [key bytes], kMSEncryptionKeySize,
                                   [initializationVector bytes], [cipherText bytes], cipherText.length, clearTextBuffer, clearTextBufferSize, &numBytesDecrypted);
  if (status != kCCSuccess) {
    MSLogError([MSAppCenter logTag], @"Error performing decryption with CCCryptorStatus: %d.", status);
  } else {
    result = [NSData dataWithBytes:clearTextBuffer length:numBytesDecrypted];
    if (!result) {
      MSLogWarning([MSAppCenter logTag], @"Could not create NSData object from decrypted bytes.");
    }
  }
  free(clearTextBuffer);
  return result;
}

- (NSString *)getCurrentKeyTag {
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

- (void)rotateToNewKeyTag:(NSString *)newKeyTag {
  NSDate *expiration = [[NSDate date] dateByAddingTimeInterval:kMSEncryptionKeyLifetimeInSeconds];
  NSString *expirationIso = [MSUtility dateToISO8601:expiration];

  // Format is {keyTag}/{expiration as iso}
  NSString *keyMetadata = [@[newKeyTag, expirationIso] componentsJoinedByString:kMSEncryptionMetadataInternalSeparator];
  [[MSUserDefaults shared] setObject:keyMetadata forKey:kMSEncryptionKeyMetadataKey];
}

- (NSData *)getKeyWithKeyTag:(NSString *)keyTag {
  NSData *key = [self.keys objectForKey:keyTag];

  // If key is not cached, try loading it from Keychain.
  if (!key) {
    NSString *stringKey = [MSKeychainUtil stringForKey:keyTag];

    // If key is not saved in Keychain, create one and save it.
    if (!stringKey) {
      key = [[self class] generateAndSaveKeyWithTag:keyTag];
    } else {
      key = [[NSData alloc] initWithBase64EncodedString:stringKey options:0];
    }
    [self.keys setObject:key forKey:keyTag];
  }
  return key;
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

+ (void *_Nonnull)generateInitializationVector {
  uint8_t *ivBytes = malloc(kCCBlockSizeAES128 * sizeof(uint8_t));
  memset((void *)ivBytes, 0x0, kCCBlockSizeAES128);
  OSStatus status = SecRandomCopyBytes(kSecRandomDefault, kCCBlockSizeAES128, ivBytes);
  if (status != errSecSuccess) {
    MSLogError([MSAppCenter logTag], @"Error generating initialization vector. Error code: %d", (int)status);
  }
  return ivBytes; // TODO free this later
}

+ (NSData *)getMetadataStringWithKeyTag:(NSString *)keyTag {

  // Format is {key tag}/{algorithm}/{cipher mode}/{padding mode}/{key length}
  NSArray *metadata = @[keyTag, kMSEncryptionAlgorithmName, kMSEncryptionCipherMode, kMSEncryptionPaddingMode, @(kMSEncryptionKeySize)];
  NSString *metadataString = [metadata componentsJoinedByString:kMSEncryptionMetadataInternalSeparator];
  return [metadataString dataUsingEncoding:NSUTF8StringEncoding];
}

@end
