#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Class for Encryption. Uses RSA algorithm with key size 256. If no key pair is specified, generates new key pair and stores it in
 * Keychain. Key pair is loaded if it is present in Keychain.
 */
@interface MSEncrypter : NSObject

- (NSString *_Nullable)encryptString:(NSString *)string;

- (NSString *_Nullable)decryptString:(NSString *)string;

@end

NS_ASSUME_NONNULL_END
