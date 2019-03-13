//
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.
//

/**
 * Protected declarations for MSServiceAbstract.
 */
@interface MSServiceAbstract ()

/**
 * Enable/Disable this service.
 *
 * @param isEnabled is this service enabled or not.
 */
- (void)setEnabled:(BOOL)isEnabled;

/**
 * Check whether this service is enabled or not.
 */
- (BOOL)isEnabled;

@end
