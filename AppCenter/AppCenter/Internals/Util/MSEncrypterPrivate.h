// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

#import "MSEncrypter.h"

NS_ASSUME_NONNULL_BEGIN

@interface MSEncrypter ()

- (instancetype)initWitKeyTag:(NSString *)keyTag;

+ (void)deleteKeyWithTag:(NSString *)keyTag;

+ (NSData *)generateKeyWithTag:(NSString *)keyTag;

//TODO document
+ (void *)generateInitializationVector;

@end

NS_ASSUME_NONNULL_END
