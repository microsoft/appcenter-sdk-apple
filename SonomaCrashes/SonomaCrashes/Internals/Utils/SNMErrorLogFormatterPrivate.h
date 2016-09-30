/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "SNMErrorLogFormatter.h"

#ifndef SNMErrorLogFormatterPrivate_h
#define SNMErrorLogFormatterPrivate_h

@interface SNMErrorLogFormatter ()

+ (NSString *)anonymizedPathFromPath:(NSString *)path;

+ (SNMBinaryImageType)imageTypeForImagePath:(NSString *)imagePath processPath:(NSString *)processPath;

+ (NSString *)errorIdForCrashReport:(SNMPLCrashReport *)report;

+ (SNMAppleErrorLog *)addProcessInfoAndApplicationPathTo:(SNMAppleErrorLog *)errorLog
                                         fromCrashReport:(SNMPLCrashReport *)crashReport;

@end

#endif /* SNMErrorLogFormatterPrivate_h */
