//
//  MSMockUserDefaults.h
//  MobileCenter
//
//  Created by Евгений Рычагов on 23/03/2017.
//  Copyright © 2017 Microsoft. All rights reserved.
//

#ifndef MSMockUserDefaults_h
#define MSMockUserDefaults_h

@interface MSMockUserDefaults : NSObject

-(void)setObject:(NSObject *)anObject forKey:(NSString *)aKey;
-(id)objectForKey:(NSString *)aKey;
- (void)removeObjectForKey:(NSString *)aKey;

/*
 * Clear dictionary
 */
-(void)stopMocking;

@end

#endif /* MSMockUserDefaults_h */
