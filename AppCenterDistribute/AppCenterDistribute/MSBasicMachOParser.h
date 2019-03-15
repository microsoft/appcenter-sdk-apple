// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

/**
 * Mach-O file parser.
 */
@interface MSBasicMachOParser : NSObject

/**
 * UUID parsed out of the current file.
 */
@property(nonatomic) NSUUID *uuid;

/**
 * Initialize a Mach-O parser for the given bundle
 *
 * @param bundle A bundle to be parsed.
 *
 * @return An instance of `MSBasicMachOParser`.
 */
- (instancetype)initWithBundle:(NSBundle *)bundle;

/**
 * Get a Mach-O parser for the main bundle.
 *
 * @return An instance of `MSBasicMachOParser`.
 */
+ (instancetype)machOParserForMainBundle;

@end
