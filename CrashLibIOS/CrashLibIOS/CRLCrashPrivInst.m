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

#import "CRLCrashPrivInst.h"

@implementation CRLCrashPrivInst

- (NSString *)category { return @"SIGILL"; }
- (NSString *)title { return @"Execute a privileged instruction"; }
- (NSString *)desc { return @"Attempt to execute an instruction that can only be executed in supervisor mode."; }

- (void)crash
{
#if __i386__
	asm volatile ( "hlt" : : : );
#elif __x86_64__
	asm volatile ( "hlt" : : : );
#elif __arm__ && __ARM_ARCH == 7 && __thumb__
	asm volatile ( ".long 0xf7f08000" : : : );
#elif __arm__ && __ARM_ARCH == 7
	asm volatile ( ".long 0xe1400070" : : : );
#elif __arm__ && __ARM_ARCH == 6 && __thumb__
	asm volatile ( ".long 0xf5ff8f00" : : : );
#elif __arm__ && __ARM_ARCH == 6
	asm volatile ( ".long 0xe14ff000" : : : );
#elif __arm64__
	/* Invalidate all EL1&0 regime stage 1 and 2 TLB entries. This should
	 * not be possible from userspace, for hopefully obvious reasons :-) */
	asm volatile ( "tlbi alle1" : : : );
#endif
}

@end
