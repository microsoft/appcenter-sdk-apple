//
//  AVACorePrivate.h
//  AvalancheSDK-iOS
//
//  Created by Christoph Wendt on 6/15/16.
//
//

#import <Foundation/Foundation.h>
#import "AVACore.h"

@class AVAFeature;
@interface AVACore ()

@property (nonatomic, strong) NSMutableArray<AVAFeature *> *features;
@property (nonatomic, copy) NSString *identifier;
@property BOOL featuresStarted;

@end
