/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "SNMErrorLogFormatter.h"

#ifndef SNMErrorLogFormatterPrivate_h
#define SNMErrorLogFormatterPrivate_h

@interface SNMErrorLogFormatter ()

+ (NSString *)anonymizedPathFromPath:(NSString *)path;

@end

#endif /* SNMErrorLogFormatterPrivate_h */
