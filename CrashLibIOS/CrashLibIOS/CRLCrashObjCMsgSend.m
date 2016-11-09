/*
 * Copyright (c) 2014 HockeyApp, Bit Stadium GmbH.
 * All rights reserved.
 *
 * Permission is hereby granted, free of charge, to any person
 * obtaining a copy of this software and associated documentation
 * files (the "Software"), to deal in the Software without
 * restriction, including without limitation the rights to use,
 * copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following
 * conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 * OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 * HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 * WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 * OTHER DEALINGS IN THE SOFTWARE.
 */

#import "CRLCrashObjCMsgSend.h"
#import <objc/message.h>

@implementation CRLCrashObjCMsgSend

- (NSString *)category { return @"Objective-C"; }
- (NSString *)title { return @"Crash inside objc_msgSend()"; }
- (NSString *)desc { return @"Send a message to an invalid object, resulting in a crash inside objc_msgSend()."; }

- (void)crash
{
    struct {
        void *isa;
    } corruptObj = {
        .isa = (void *) 42
    };
  
#if __i386__ && !TARGET_IPHONE_SIMULATOR
#define __bridge
#endif
  [(__bridge id)&corruptObj stringWithFormat:
   @"%u, %u, %u, %u, %u, %u, %f, %f, %c, %c, %s, %s, %@, %@"
   " %u, %u, %u, %u, %u, %u, %f, %f, %c, %c, %s, %s, %@, %@",
   0x3, 0x4, 0x5, 0x6, 0x7, 0x8, 9.0, 10.0, 'a', 'b', "C", "D", @"E", @"F",
   0x3, 0x4, 0x5, 0x6, 0x7, 0x8, 9.0, 10.0, 'a', 'b', "C", "D", @"E", @"F"];
}

@end
