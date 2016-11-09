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

#import "CRLCrashUndefInst.h"

@implementation CRLCrashUndefInst

- (NSString *)category { return @"SIGILL"; }
- (NSString *)title { return @"Execute an undefined instruction"; }
- (NSString *)desc { return @"Attempt to execute an instructiondinn not to be defined on the current architecture."; }

- (void)crash
{
#if __i386__
	asm volatile ( "ud2" : : : );
#elif __x86_64__
	asm volatile ( "ud2" : : : );
#elif __arm__ && __ARM_ARCH == 7 && __thumb__
	asm volatile ( ".word 0xde00" : : : );
#elif __arm__ && __ARM_ARCH == 7
	asm volatile ( ".long 0xf7f8a000" : : : );
#elif __arm__ && __ARM_ARCH == 6 && __thumb__
	asm volatile ( ".word 0xde00" : : : );
#elif __arm__ && __ARM_ARCH == 6
	asm volatile ( ".long 0xf7f8a000" : : : );
#elif __arm64__
	asm volatile ( ".long 0xf7f8a000" : : : );
#endif
}

@end
