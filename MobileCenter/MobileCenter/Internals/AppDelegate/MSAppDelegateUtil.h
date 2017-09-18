#import <Foundation/Foundation.h>
#if TARGET_OS_OSX
#import <AppKit/AppKit.h>
#ifndef MSOriginalAppDelegate
#define MSOriginalAppDelegate NSApplicationDelegate
#endif
#ifndef MSApplication
#define MSApplication NSApplication
#endif
#else
#import <UIKit/UIKit.h>
#ifndef MSOriginalAppDelegate
#define MSOriginalAppDelegate UIApplicationDelegate
#endif
#ifndef MSApplication
#define MSApplication UIApplication
#endif
#endif

