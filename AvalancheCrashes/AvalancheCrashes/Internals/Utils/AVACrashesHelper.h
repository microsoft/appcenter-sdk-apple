/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import <Foundation/Foundation.h>


@interface AVACrashesHelper : NSObject

/**
 * Returns the directory for storing and reading crash reports for this app.
 *
 * @return The directory containing crash reports for this app.
 */
+ (NSString *)crashesDir;

/**
 * Determines if the SDK is used inside an app extension.
 *
 * @return YES, if the SDK is used as inside an app extension.
 */
+ (BOOL)isAppExtension;

/**
 * Determines if the app is running with a debugger attached.
 *
 *  @return YES, if the app is running with a debugger attached.
 */
+ (BOOL)isDebuggerAttached;

@end
