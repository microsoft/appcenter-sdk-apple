#import <Foundation/Foundation.h>

#import "MSOneCollectorIngestion.h"

@interface MSOneCollectorIngestion ()

/**
 * Obfuscate the header values.
 *
 * @param value The value that will be obfuscated.
 * @param key The HTTP header key.
 *
 * @return The obfuscated value.
 */
- (NSString *)obfuscateHeaderValue:(NSString *)value forKey:(NSString *)key;

@end
