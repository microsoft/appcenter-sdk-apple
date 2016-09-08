/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "AvalancheHub+Internal.h"
#import <Foundation/Foundation.h>

@interface AVAStackFrame : NSObject <AVASerializableObject>

/*
 * Frame address [optional].
 */
@property(nonatomic, nullable) NSString *address;

/*
 * Symbolized code line [optional].
 */
@property(nonatomic, nullable) NSString *code;

/*
 * The fully qualified name of the Class containing the execution point represented by this stack trace element [optional].
 */
@property(nonatomic, nullable) NSString *className;

/*
 * The name of the method containing the execution point represented by this stack trace element [optional].
 */
@property(nonatomic, nullable) NSString *methodName;

/*
 * The line number of the source line containing the execution point represented by this stack trace element [optional].
 */
@property(nonatomic, nullable) NSNumber *lineNumber;

/*
 * The name of the file containing the execution point represented by this stack trace element [optional].
 */
@property(nonatomic, nullable) NSString *fileName;


@end
