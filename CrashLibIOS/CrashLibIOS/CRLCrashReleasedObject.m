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

#import "CRLCrashReleasedObject.h"
#import <objc/message.h>

@implementation CRLCrashReleasedObject

- (NSString *)category { return @"Objective-C"; }
- (NSString *)title { return @"Message a released object"; }
- (NSString *)desc { return @"Send a message to an object whose memory has already been freed."; }

- (void)crash
{
#if __i386__ && !TARGET_IPHONE_SIMULATOR
	NSObject *object = [[NSObject alloc] init];
#else
	NSObject * __unsafe_unretained object = (__bridge NSObject *)CFBridgingRetain([[NSObject alloc] init]);
#endif
	
#if __i386__ && !TARGET_IPHONE_SIMULATOR
	[object release];
#else
	CFRelease((__bridge CFTypeRef)object);
#endif
	^ __attribute__((noreturn)) {
		for (;;) {
			[object self];
			[object description];
			[object debugDescription];
		}
	}();
}

@end
