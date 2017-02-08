/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

@import Foundation;

@interface MSCrashesUtil : NSObject

/**
 * Returns the directory for storing and reading crash reports for this app.
 *
 * @return The directory containing crash reports for this app.
 */
+ (NSString *)crashesDir;

@end
