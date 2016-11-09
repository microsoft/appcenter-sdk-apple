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

#import "CRLCrashGarbage.h"
#import <sys/mman.h>

@implementation CRLCrashGarbage

- (NSString *)category { return @"SIGSEGV"; }
- (NSString *)title { return @"Dereference a bad pointer"; }
- (NSString *)desc { return @"Attempt to read from a garbage pointer that's not mapped but also isn't NULL."; }

- (void)crash
{
	void *ptr = mmap(NULL, (size_t)getpagesize(), PROT_NONE, MAP_ANON | MAP_PRIVATE, -1, 0);
	
	if (ptr != MAP_FAILED)
		munmap(ptr, (size_t)getpagesize());
	
#if __i386__
	asm volatile ( "mov %0, %%eax\n\tmov (%%eax), %%eax" : : "X" (ptr) : "memory", "eax" );
#elif __x86_64__
	asm volatile ( "mov %0, %%rax\n\tmov (%%rax), %%rax" : : "X" (ptr) : "memory", "rax" );
#elif __arm__ && __ARM_ARCH == 7
	asm volatile ( "mov r4, %0\n\tldr r4, [r4]" : : "X" (ptr) : "memory", "r4" );
#elif __arm__ && __ARM_ARCH == 6
	asm volatile ( "mov r4, %0\n\tldr r4, [r4]" : : "X" (ptr) : "memory", "r4" );
#elif __arm64__
	asm volatile ( "mov x4, %0\n\tldr x4, [x4]" : : "X" (ptr) : "memory", "x4" );
#endif
}

@end
