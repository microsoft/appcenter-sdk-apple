// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

/**
 * Common schema metadata type identifiers.
 */
static const int kMSLongMetadataTypeId = 4;
static const int kMSDoubleMetadataTypeId = 6;
static const int kMSDateTimeMetadataTypeId = 9;

/**
 * Minimum flush interval for channel.
 */
static NSUInteger const kMSFlushIntervalMinimum = 3;

/**
 * Maximum flush interval for channel.
 */
static NSUInteger const kMSFlushIntervalMaximum = 24 * 60 * 60;
