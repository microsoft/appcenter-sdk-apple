#import <Foundation/Foundation.h>

#import "MSChannelDelegate.h"

@interface MSOneCollectorChannelDelegate : NSObject <MSChannelDelegate>

- (instancetype)initWithInstallId:(NSUUID *)installId;

@end
