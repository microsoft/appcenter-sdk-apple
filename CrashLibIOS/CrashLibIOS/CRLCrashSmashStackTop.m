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

#import "CRLCrashSmashStackTop.h"

@implementation CRLCrashSmashStackTop

- (NSString *)category { return @"Various"; }
- (NSString *)title { return @"Smash the top of the stack"; }
- (NSString *)desc { return @""
  "Overwrite data above the current stack pointer. This will destroy the current stack trace. "
  "Reporting of this crash is expected to fail. Succeeding is basically luck.";
}

- (void)crash
{
	void *sp = NULL;
	
#if __i386__
	asm volatile ( "mov %%esp, %0" : "=X" (sp) : : );
#elif __x86_64__
	asm volatile ( "mov %%rsp, %0" : "=X" (sp) : : );
#elif __arm__ && __ARM_ARCH == 7
	asm volatile ( "mov %0, sp" : "=X" (sp) : : );
#elif __arm__ && __ARM_ARCH == 6
	asm volatile ( "mov %0, sp" : "=X" (sp) : : );
#elif __arm64__
	asm volatile ( "mov %0, sp" : "=X" (sp) : : );
#endif
	
	memset(sp - 0x100, 0xa5, 0x100);
}

@end
