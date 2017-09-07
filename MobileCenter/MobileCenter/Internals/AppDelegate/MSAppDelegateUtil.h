#if TARGET_OS_OSX
#import <AppKit/AppKit.h>
#ifndef MSOriginalAppDelegate
#define MSOriginalAppDelegate NSApplicationDelegate
#endif
#ifndef MSOriginalApplication
#define MSOriginalApplication NSApplication
#endif
#else
#import <UIKit/UIKit.h>
#ifndef MSOriginalAppDelegate
#define MSOriginalAppDelegate UIApplicationDelegate
#endif
#ifndef MSOriginalApplication
#define MSOriginalApplication UIApplication
#endif
#endif

