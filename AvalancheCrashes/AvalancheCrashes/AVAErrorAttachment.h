//
//  AVAErrorAttachment.h
//  AvalancheCrashes
//
//  Created by Benjamin Reimold on 8/1/16.
//  Copyright © 2016 Microsoft. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AVABinaryAttachment;

@interface AVAErrorAttachment : NSObject

@property (nonatomic, copy) NSString *textAttachment;
@property (nonatomic, readwrite) AVABinaryAttachment *attachmentFile;


@end
