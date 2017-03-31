#import <Foundation/Foundation.h>

@interface MSCustomProperties : NSObject

- (MSCustomProperties *)setString:(NSString *)value forKey:(NSString *)key;

- (MSCustomProperties *)setNumber:(NSNumber *)value forKey:(NSString *)key;

- (MSCustomProperties *)setBool:(BOOL)value forKey:(NSString *)key;

- (MSCustomProperties *)setDate:(NSDate *)value forKey:(NSString *)key;

- (MSCustomProperties *)clearPropertyForKey:(NSString *)key;

@end
