// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

#import "MSSerializableDocument.h"

@interface MSTestDocument : NSObject <MSSerializableDocument>

@property(copy, nonatomic) NSString *property1;
@property(copy, nonatomic) NSNumber *property2;

/**
 * Return a document (JSON) fixture by name.
 *
 * @param fixture The name of the fixture (in Fixtures folder).
 * @return The fixture's data.
 */
+ (NSData *)getDocumentFixture:(NSString *)fixture;

@end
