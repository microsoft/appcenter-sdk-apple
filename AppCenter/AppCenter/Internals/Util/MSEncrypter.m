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

@property(atomic) NSData *originalKeyData;
@property(atomic) NSData *alternateKeyData;

@end

@implementation MSEncrypter

- (NSString *_Nullable)encryptString:(NSString *)string {
  NSData *dataToEncrypt = [string dataUsingEncoding:NSUTF8StringEncoding];
  NSData *encryptedData = [self encryptData:dataToEncrypt];
  return [encryptedData base64EncodedStringWithOptions:0];
}

- (NSData *_Nullable)encryptData:(NSData *)data {
  NSString *keyTag = [MSEncrypter getCurrentKeyTag];
  NSData *key = [self getKeyWithKeyTag:keyTag];
  NSData *initializationVector = [MSEncrypter generateInitializationVector];
  NSData *result = [MSEncrypter performCryptoOperation:kCCEncrypt input:data initializationVector:initializationVector key:key];
  if (result) {
    NSData *metadata = [MSEncrypter getMetadataStringWithKeyTag:keyTag];
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
  if (metadata) {

    // Extract key from metadata.
    NSString *keyTag = [metadata componentsSeparatedByString:kMSEncryptionMetadataInternalSeparator][0];

    // Metadata, separator, and initialization vector.
    size_t cipherTextPrefixLength = metadataLocation + 1 + kCCBlockSizeAES128;
    NSRange cipherTextRange = NSMakeRange(cipherTextPrefixLength, [data length] - cipherTextPrefixLength);
    NSRange ivRange = NSMakeRange(metadataLocation + 1, kCCBlockSizeAES128);
    initializationVector = [data subdataWithRange:ivRange];
    cipherText = [data subdataWithRange:cipherTextRange];
    key = [self getKeyWithKeyTag:keyTag];
  } else {

    // If there is no metadata, this is old data, so use the old key and an empty initialization vector.
    key = [self getKeyWithKeyTag:kMSEncryptionKeyTagOriginal];
    cipherText = data;
  }
  return [MSEncrypter performCryptoOperation:kCCDecrypt input:cipherText initializationVector:initializationVector key:key];
}

+ (NSString *)getCurrentKeyTag {
  @synchronized(classLock) {
    NSString *keyMetadata = [MS_APP_CENTER_USER_DEFAULTS objectForKey:kMSEncryptionKeyMetadataKey];
    if (!keyMetadata) {
      [self rotateToNewKeyTag:kMSEncryptionKeyTagAlternate];
      return kMSEncryptionKeyTagAlternate;
    }

    // Format is {keyTag}/{expiration as iso}.
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

  // Format is {keyTag}/{expiration as iso}.
  NSString *keyMetadata = [@[ newKeyTag, expirationIso ] componentsJoinedByString:kMSEncryptionMetadataInternalSeparator];
  [MS_APP_CENTER_USER_DEFAULTS setObject:keyMetadata forKey:kMSEncryptionKeyMetadataKey];
}

- (NSData *)getKeyWithKeyTag:(NSString *)keyTag {
  NSData *keyData;
  BOOL isOriginalKeyTag = [keyTag isEqualToString:kMSEncryptionKeyTagOriginal];
  keyData = isOriginalKeyTag ? self.originalKeyData : self.alternateKeyData;

  // Key was found in memory.
  if (keyData) {
    return keyData;
  }

  // If key is not in memory; try loading it from Keychain.
  NSString *stringKey = [MSKeychainUtil stringForKey:keyTag statusCode:nil];
  if (stringKey) {
    keyData = [[NSData alloc] initWithBase64EncodedString:stringKey options:0];
  } else {

    // If key is not saved in Keychain, create one and save it. This will only happen at most twice after an app is installed.
    @synchronized(classLock) {

      // Recheck if the key has been written from another thread.
      stringKey = [MSKeychainUtil stringForKey:keyTag statusCode:nil];
      if (!stringKey) {
        keyData = [MSEncrypter generateAndSaveKeyWithTag:keyTag];
      }
    }
    if (isOriginalKeyTag) {
      self.originalKeyData = keyData;
    } else {
      self.alternateKeyData = keyData;
    }
  }
  return keyData;
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
      MSLogError([MSAppCenter logTag], @"Could not create NSData object from encrypted or decrypted bytes.");
    }
  }
  free(outputBuffer);
  return result;
}

+ (NSData *)generateAndSaveKeyWithTag:(NSString *)keyTag {
  NSData *resultKey = nil;
  uint8_t *keyBytes = nil;
  keyBytes = malloc(kMSEncryptionKeySize * sizeof(uint8_t));
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
  OSStatus status = SecRandomCopyBytes(kSecRandomDefault, kCCBlockSizeAES128, ivBytes);
  if (status != errSecSuccess) {
    MSLogError([MSAppCenter logTag], @"Error generating initialization vector. Error code: %d", (int)status);
  }
  NSData *initializationVector = [NSData dataWithBytes:ivBytes length:kCCBlockSizeAES128];
  free(ivBytes);
  return initializationVector;
}

+ (NSData *)getMetadataStringWithKeyTag:(NSString *)keyTag {

  // Format is {key tag}/{algorithm}/{cipher mode}/{padding mode}/{key length}
  NSArray *metadata = @[ keyTag, kMSEncryptionAlgorithmName, kMSEncryptionCipherMode, kMSEncryptionPaddingMode, @(kMSEncryptionKeySize) ];
  NSString *metadataString = [metadata componentsJoinedByString:kMSEncryptionMetadataInternalSeparator];
  return [metadataString dataUsingEncoding:NSUTF8StringEncoding];
}

@end
