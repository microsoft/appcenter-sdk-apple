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

#import "CRLCrashOverwriteLinkRegister.h"

@implementation CRLCrashOverwriteLinkRegister

- (NSString *)category { return @"Various"; }
- (NSString *)title { return @"Overwrite link register, then crash"; }
- (NSString *)desc { return @""
    "Trigger a crash after first overwriting the link register. "
    "Crash reporters that insert a stack frame based on the link register can generate duplicate or incorrect stack frames in the report. "
    "This does not apply to architectures that do not use a link register, such as x86-64.";
}

- (void)crash {
    /* Call a method to trigger modification of LR. We use the result below to
     * convince the compiler to order this function the way we want it. */
    uintptr_t ptr = (uintptr_t) [NSObject class];
    
    /* Make-work code that simply advances the PC to better demonstrate the discrepency. We use the
     * 'ptr' value here to make sure the compiler doesn't optimize-away this code, or re-order it below
     * the method call. */
    ptr += ptr;
    ptr -= 42;
    ptr += ptr % (ptr - 42);

    /* Crash within the method (using a write to the NULL page); the link register will be pointing at
     * the make-work code. We use the 'ptr' value to control compiler ordering. */
    *((uintptr_t volatile *)NULL) = ptr;
}


@end
