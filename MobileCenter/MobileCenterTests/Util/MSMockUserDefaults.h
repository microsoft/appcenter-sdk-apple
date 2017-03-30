#import <Foundation/Foundation.h>

@interface MSMockUserDefaults : NSObject

-(void)setObject:(NSObject *)anObject forKey:(NSString *)aKey;
-(id)objectForKey:(NSString *)aKey;
- (void)removeObjectForKey:(NSString *)aKey;

/*
 * Clear dictionary
 */
-(void)stopMocking;

@end
