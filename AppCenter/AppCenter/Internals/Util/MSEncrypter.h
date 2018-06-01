#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Utility class for Encryption.
 */
@interface MSEncrypter : NSObject

- (instancetype)initWithDefaultKeyPair;

- (instancetype)initWithPublicKey:(SecKeyRef)publicKey andPrivateKey:(SecKeyRef)privateKey;

- (NSString *_Nullable)encryptString:(NSString *)string;

- (NSString *_Nullable)decryptString:(NSString *)data;

@end

NS_ASSUME_NONNULL_END

