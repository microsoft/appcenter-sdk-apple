// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

#import "MSModel.h"
#import "MSSerializableObject.h"

@class MSAppExtension;
@class MSDeviceExtension;
@class MSLocExtension;
@class MSMetadataExtension;
@class MSNetExtension;
@class MSOSExtension;
@class MSProtocolExtension;
@class MSSDKExtension;
@class MSUserExtension;

static NSString *const kMSCSAppExt = @"app";
static NSString *const kMSCSDeviceExt = @"device";
static NSString *const kMSCSLocExt = @"loc";
static NSString *const kMSCSMetadataExt = @"metadata";
static NSString *const kMSCSNetExt = @"net";
static NSString *const kMSCSOSExt = @"os";
static NSString *const kMSCSProtocolExt = @"protocol";
static NSString *const kMSCSUserExt = @"user";
static NSString *const kMSCSSDKExt = @"sdk";

/**
 * Part A extensions.
 */
@interface MSCSExtensions : NSObject <MSSerializableObject, MSModel>

/**
 * The Metadata extension.
 */
@property(nonatomic) MSMetadataExtension *metadataExt;

/**
 * The Protocol extension.
 */
@property(nonatomic) MSProtocolExtension *protocolExt;

/**
 * The User extension.
 */
@property(nonatomic) MSUserExtension *userExt;

/**
 * The Device extension.
 */
@property(nonatomic) MSDeviceExtension *deviceExt;

/**
 * The OS extension.
 */
@property(nonatomic) MSOSExtension *osExt;

/**
 * The App extension.
 */
@property(nonatomic) MSAppExtension *appExt;

/**
 * The network extension.
 */
@property(nonatomic) MSNetExtension *netExt;

/**
 * The SDK extension.
 */
@property(nonatomic) MSSDKExtension *sdkExt;

/**
 * The Loc extension.
 */
@property(nonatomic) MSLocExtension *locExt;

@end
