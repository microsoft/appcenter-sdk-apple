//
//  AVAPublicErrorLog.h
//  AvalancheCrashes
//
//  Created by Benjamin Reimold on 8/1/16.
//  Copyright © 2016 Microsoft. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AVAPublicErrorLog : NSObject

@property (nonatomic, copy, readonly) NSString *crashReason;

@end
