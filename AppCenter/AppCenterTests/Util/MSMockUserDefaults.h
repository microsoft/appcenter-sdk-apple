#import <Foundation/Foundation.h>

#import "MSUserDefaults.h"

@interface MSMockUserDefaults : MSUserDefaults

/*
 * Clear dictionary
 */
- (void)stopMocking;

@end
