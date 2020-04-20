// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <CommonCrypto/CommonCryptor.h>
#import <Foundation/Foundation.h>

#import "MSEncrypter.h"

NS_ASSUME_NONNULL_BEGIN

static int const kMSEncryptionAlgorithm = kCCAlgorithmAES;
static NSString *const kMSEncryptionAlgorithmName = @"AES";
static NSString *const kMSEncryptionCipherMode = @"CBC";

// One year.
static NSTimeInterval const kMSEncryptionKeyLifetimeInSeconds = 365 * 24 * 60 * 60;
static int const kMSEncryptionKeySize = kCCKeySizeAES256;
static NSString *const kMSEncryptionKeyMetadataKey = @"EncryptionKeyMetadata";
static NSString *const kMSEncryptionKeyTagAlternate = @"kMSEncryptionKeyTagAlternate";
static NSString *const kMSEncryptionKeyTagOriginal = @"kMSEncryptionKeyTag";

// This separator is used for key metadata, as well as between metadata that is prepended to the cipher text.
static NSString *const kMSEncryptionMetadataInternalSeparator = @"/";

// This separator is only used between the metadata and cipher text of the encryption result.
static NSString *const kMSEncryptionMetadataSeparator = @":";
static NSString *const kMSEncryptionPaddingMode = @"PKCS7";

@interface MSEncrypter ()

@end

NS_ASSUME_NONNULL_END
