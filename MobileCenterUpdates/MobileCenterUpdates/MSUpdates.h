/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "MSServiceAbstract.h"
#import "MSSender.h"

@interface MSUpdates : MSServiceAbstract

/**
 * A sender instance that is used to send update request to the backend.
 */
@property(nonatomic) id<MSSender> sender;

@end
