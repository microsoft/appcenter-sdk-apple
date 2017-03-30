#import <Foundation/Foundation.h>

#import "MSSerializableObject.h"
#import "MobileCenter+Internal.h"

@interface MSStackFrame : NSObject <MSSerializableObject>

/*
 * Frame address [optional].
 */
@property(nonatomic, copy) NSString *address;

/*
 * Symbolized code line [optional].
 */
@property(nonatomic, copy) NSString *code;

/*
 * The fully qualified name of the Class containing the execution point represented by this stack trace element
 * [optional].
 */
@property(nonatomic, copy) NSString *className;

/*
 * The name of the method containing the execution point represented by this stack trace element [optional].
 */
@property(nonatomic, copy) NSString *methodName;

/*
 * The line number of the source line containing the execution point represented by this stack trace element [optional].
 */
@property(nonatomic, copy) NSNumber *lineNumber;

/*
 * The name of the file containing the execution point represented by this stack trace element [optional].
 */
@property(nonatomic, copy) NSString *fileName;

/**
 * Is equal to another stack frame
 *
 * @param object Stack frame
 *
 * @return Return YES if equal and NO if not equal
 */
- (BOOL)isEqual:(id)object;

@end
