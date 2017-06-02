/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import <Foundation/Foundation.h>

@interface EventLog : NSObject

@property (nonatomic) NSString *eventName;
@property (nonatomic) NSMutableDictionary<NSString *,NSString *> *properties;

@end
