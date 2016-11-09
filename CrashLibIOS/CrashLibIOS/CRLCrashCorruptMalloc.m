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

#import "CRLCrashCorruptMalloc.h"
#import <malloc/malloc.h>
#import <mach/mach.h>

@implementation CRLCrashCorruptMalloc

- (NSString *)category { return @"Various"; }
- (NSString *)title { return @"Corrupt malloc()'s internal tracking information"; }
- (NSString *)desc { return @""
  "Write garbage into data areas used by malloc to track memory allocations. "
  "This simulates the kind of heap overflow and/or heap corruption likely to occur in an application; "
  "if the crash reporter itself uses malloc, the corrupted heap will likely trigger a crash in the crash reporter itself.";
}

- (void)crash {
  /* Smash the heap, and keep smashing it until we eventually hit something non-writable, or trigger
   * a malloc error (e.g., in NSLog). */
  uint8_t *memory = malloc(10);
  while (true) {
    NSLog(@"Smashing [%p - %p]", memory, memory + PAGE_SIZE);
    memset((void *) trunc_page((vm_address_t)memory), 0xAB, PAGE_SIZE);
    memory += PAGE_SIZE;
  }
}

@end
