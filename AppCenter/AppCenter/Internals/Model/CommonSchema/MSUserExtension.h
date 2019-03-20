// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

#import "MSModel.h"
#import "MSSerializableObject.h"

static NSString *const kMSUserLocale = @"locale";
static NSString *const kMSUserLocalId = @"localId";

/**
 * The “user” extension tracks common user elements that are not available in the core envelope.
 */
@interface MSUserExtension : NSObject <MSSerializableObject, MSModel>

/**
 * Local Id.
 */
@property(nonatomic, copy) NSString *localId;

/**
 * User's locale.
 */
@property(nonatomic, copy) NSString *locale;

@end
