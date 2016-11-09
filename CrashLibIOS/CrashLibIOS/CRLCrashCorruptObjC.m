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

#import "CRLCrashCorruptObjC.h"
#import <dlfcn.h>
#import <objc/message.h>
#import <mach-o/loader.h>
#import <mach-o/nlist.h>

@implementation CRLCrashCorruptObjC

- (NSString *)category { return @"Various"; }
- (NSString *)title { return @"Corrupt the Objective-C runtime's structures"; }
- (NSString *)desc { return @""
  "Write garbage into data areas used by the Objective-C runtime to track classes and objects. "
  "Bugs of this nature are why crash reporters cannot use Objective-C in their crash handling code, "
  "as attempting to do so is likely to lead to a crash in the crash reporting code.";
}

- (void)crash
{
	Class objClass = [NSObject class];
	
	// VERY VERY PRIVATE INTERNAL RUNTIME DETAILS VERY VERY EVIL THIS IS BAD!!!
	struct objc_cache_t {
		uintptr_t mask;            /* total = mask + 1 */
		uintptr_t occupied;        
		void *buckets[1];
	};
	struct objc_class_t {
		struct objc_class_t *isa;
		struct objc_class_t *superclass;
		struct objc_cache_t cache;
		IMP *vtable;
		uintptr_t data_NEVER_USE;  // class_rw_t * plus custom rr/alloc flags
	};

#if __i386__ && !TARGET_IPHONE_SIMULATOR
#define __bridge
#endif

	struct objc_class_t *objClassInternal = (__bridge struct objc_class_t *)objClass;
	
	// Trashes NSObject's method cache
	memset(&objClassInternal->cache, 0xa5, sizeof(struct objc_cache_t));
	
	[self description];
}

@end
