// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

#define ARRAY_FROM_ARGS(...) ({\
 [NSArray arrayWithObjects: __VA_ARGS__ nil];\
})

#define INVOKE(c) PRIMITIVE_CAT(INVOKE_, c)
#define INVOKE_1(t, ...)
#define INVOKE_0(t, ...) EXECUTE_INVOCATION(t)

#define PRIMITIVE_CAT(a, ...) a ## __VA_ARGS__

#define CHECK_N(x, n, ...) n
#define CHECK(...) CHECK_N(__VA_ARGS__, 0,)
#define PROBE(x) x, 1,

#define IS_PAREN(x) CHECK(IS_PAREN_PROBE x)
#define IS_PAREN_PROBE(...) PROBE(~)

#define PRIMITIVE_COMPARE(x, y) IS_PAREN \
( \
 COMPARE_ ## x ( COMPARE_ ## y) (())  \
)

#define COMPARE_void(x) x
#define COMPARE_NOT_USABLE(x) x

#define EXECUTE_INVOCATION(invoke) ({ \
 [invoke getReturnValue:&results];\
})

#define Invocation(object, selectorName, objects) ({ \
 SEL selectors = NSSelectorFromString(selectorName); \
 NSMethodSignature *signature = [object methodSignatureForSelector:selectors]; \
 NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature]; \
 [invocation setTarget:object]; \
 [invocation setSelector:selectors]; \
 int index = 2; \
 for(id value in objects) {\
  void * values = (__bridge void *)value;    \
  [invocation setArgument:&values atIndex:index++];\
 }\
 [invocation retainArguments];\
 [invocation invoke];\
 invocation;\
})

#define MS_EXECUTE_TASK(type, object, selectorName, ...) ({ \
 void *results = nil;\
 NSInvocation* invocatedObject = Invocation(object, @#selectorName, ARRAY_FROM_ARGS(__VA_ARGS__));\
 INVOKE(PRIMITIVE_COMPARE(type,NOT_USABLE))(invocatedObject); \
 results;\
})

#define MS_DISPATCH_SELECTOR_OBJECT(type, object, selectorName, ...) ({ \
 (__bridge type)MS_EXECUTE_TASK(type, object, selectorName, __VA_ARGS__); \
})

#define MS_DISPATCH_SELECTOR(type, object, selectorName, ...) ({ \
 (type)MS_EXECUTE_TASK(type, object, selectorName, __VA_ARGS__); \
})

@interface MSPerformSelectorUtil : NSObject

+ (void)performSelectorOnMainThread:(NSObject *)source withSelector:(SEL)selector withObjects:(NSObject *)objects, ...;

@end
