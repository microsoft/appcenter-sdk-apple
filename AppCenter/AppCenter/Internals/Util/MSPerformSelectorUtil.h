// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

#define ARRAY_FROM_ARGS(...)                                                                                                               \
  ({                                                                                                                                       \
    NSMutableArray *initedArray = [NSMutableArray arrayWithObjects:[NSNull null], ##__VA_ARGS__, nil];                                     \
    [initedArray removeObjectAtIndex:0];                                                                                                   \
    initedArray;                                                                                                                           \
  })

#define IS_EMPTY(...) ({ (sizeof((char[]){#__VA_ARGS__}) == 1); })

#define INVOKE(c) PRIMITIVE_CAT(INVOKE_, c)
#define INVOKE_1(t, ...) t
#define INVOKE_0(t, ...) EXECUTE_INVOCATION(t)

#define GET_INVOKE(c) PRIMITIVE_CAT(GET_INVOKE_, c)
#define GET_INVOKE_1(t, ...)
#define GET_INVOKE_0(t, ...) t

#define PRIMITIVE_CAT(a, ...) a##__VA_ARGS__

#define CHECK_N(x, n, ...) n
#define CHECK(...) CHECK_N(__VA_ARGS__, 0, )
#define PROBE(x) x, 1,

#define IS_PAREN(x) CHECK(IS_PAREN_PROBE x)
#define IS_PAREN_PROBE(...) PROBE(~)

#define PRIMITIVE_COMPARE(x, y) IS_PAREN(COMPARE_##x(COMPARE_##y)(()))

#define COMPARE_void(x) x
#define COMPARE_NOT_USABLE(x) x

#define EXECUTE_INVOCATION(invoke) ({ [invoke getReturnValue:&results]; })

#define Invocation(type, object, selectorName, objects)                                                                                    \
  ({                                                                                                                                       \
    SEL selectors = NSSelectorFromString(selectorName);                                                                                    \
    NSMethodSignature *signature = [object methodSignatureForSelector:selectors];                                                          \
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];                                                     \
    [invocation setTarget:object];                                                                                                         \
    [invocation setSelector:selectors];                                                                                                    \
    int index = 2;                                                                                                                         \
    for (id value in objects) {                                                                                                            \
      void *values = (__bridge void *)value;                                                                                               \
      [invocation setArgument:&values atIndex:index++];                                                                                    \
    }                                                                                                                                      \
    [invocation retainArguments];                                                                                                          \
    [invocation invoke];                                                                                                                   \
    GET_INVOKE(PRIMITIVE_COMPARE(type, NOT_USABLE))(invocation);                                                                           \
  })

#define MS_EXECUTE_TASK(type, object, selectorName, ...)                                                                                   \
  ({                                                                                                                                       \
    void *results = nil;                                                                                                                   \
    INVOKE(PRIMITIVE_COMPARE(type, NOT_USABLE))                                                                                            \
    (Invocation(type, object, @ #selectorName, ARRAY_FROM_ARGS(__VA_ARGS__)),                                                              \
     Invocation(type, object, @ #selectorName, ARRAY_FROM_ARGS(__VA_ARGS__)));                                                             \
    results;                                                                                                                               \
  })

#define MS_DISPATCH_SELECTOR_OBJECT(type, object, selectorName, ...)                                                                       \
  ({ (__bridge type) MS_EXECUTE_TASK(type, object, selectorName, __VA_ARGS__); })

#define MS_DISPATCH_SELECTOR(type, object, selectorName, ...) ({ (type) MS_EXECUTE_TASK(type, object, selectorName, __VA_ARGS__); })

@interface MSPerformSelectorUtil : NSObject

+ (void)performSelectorOnMainThread:(NSObject *)source withSelector:(SEL)selector withObjects:(NSObject *)objects, ...;

@end
