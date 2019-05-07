// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

typedef NS_OPTIONS(NSUInteger, MSFlags) {
  MSFlagsNone = (0 << 0),                // => 00000000
  MSFlagNormal = (1 << 0),               // => 00000001
  MSFlagCritial = (1 << 1),              // => 00000010
  MSFlagsPersistenceNormal = MSFlagNormal,
  MSFlagsPersistenceCritical = MSFlagCritial,
  MSFlagsPersistenceNone = MSFlagsNone,
  MSFlagsDefault = (MSFlagNormal | MSFlagsPersistenceNormal)
};
