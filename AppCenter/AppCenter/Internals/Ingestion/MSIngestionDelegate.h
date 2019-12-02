// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

@protocol MSIngestionProtocol;

@protocol MSIngestionDelegate <NSObject>

@optional

/**
 * Triggered after ingestion has paused its state.
 *
 * @param ingestion The ingestion instance.
 */
- (void)ingestionDidPause:(id<MSIngestionProtocol>)ingestion;

/**
 * Triggered after ingestion has resumed its state.
 *
 * @param ingestion The ingestion instance.
 */
- (void)ingestionDidResume:(id<MSIngestionProtocol>)ingestion;

@end
