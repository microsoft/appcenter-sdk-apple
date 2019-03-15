// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

#import "MSModel.h"
#import "MSSerializableObject.h"

static NSString *const kMSDevMake = @"devMake";
static NSString *const kMSDevModel = @"devModel";
static NSString *const kMSTicketKeys = @"ticketKeys";

/**
 * The Protocol extension contains device specific information.
 */
@interface MSProtocolExtension : NSObject <MSSerializableObject, MSModel>

/**
 * Ticket keys.
 */
@property(nonatomic) NSArray<NSString *> *ticketKeys;

/**
 * The device's manufacturer.
 */
@property(nonatomic, copy) NSString *devMake;

/**
 * The device's model.
 */
@property(nonatomic, copy) NSString *devModel;

@end
