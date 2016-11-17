/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import <Foundation/Foundation.h>

@interface CRLCrash : NSObject

+ (NSArray *)allCrashes;

+ (void)registerCrash:(CRLCrash *)crash;

+ (void)unregisterCrash:(CRLCrash *)crash;

@property(nonatomic, copy, readonly) NSString *category;
@property(nonatomic, copy, readonly) NSString *title;
@property(nonatomic, copy, readonly) NSString *desc;

- (void)crash;

@end
