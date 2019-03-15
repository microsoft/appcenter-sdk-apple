// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

#import "MSModel.h"
#import "MSSerializableObject.h"

static NSString *const kMSAppId = @"id";
static NSString *const kMSAppLocale = @"locale";
static NSString *const kMSAppName = @"name";
static NSString *const kMSAppVer = @"ver";
static NSString *const kMSAppUserId = @"userId";

/**
 * The App extension contains data specified by the application.
 */
@interface MSAppExtension : NSObject <MSSerializableObject, MSModel>

/**
 * The application's bundle identifier.
 */
@property(nonatomic, copy) NSString *appId;

/**
 * The application's version.
 */
@property(nonatomic, copy) NSString *ver;

/**
 * The application's name.
 */
@property(nonatomic, copy) NSString *name;

/**
 * The application's locale.
 */
@property(nonatomic, copy) NSString *locale;

/**
 * The application's userId.
 */
@property(nonatomic, copy) NSString *userId;

@end
