// Licensed under the MIT License.

#import <Foundation/Foundation.h>

#define ARRAY_FROM_ARGS(...)                                                                                                               \
  ({                                                                                                                                       \
    NSMutableArray *initedArray = [NSMutableArray arrayWithObjects:[NSNull null], ##__VA_ARGS__, nil];                                     \
    [initedArray removeObjectAtIndex:0];                                                                                                   \
    initedArray;                                                                                                                           \
  })

#define MS_DISPATCH_SELECTOR(object, selectorName, ...)                                                                                          \
  ({                                                                                                                                       \
    SEL selectors = NSSelectorFromString(@#selectorName);                                                                                    \
    NSMethodSignature *signature = [object methodSignatureForSelector:selectors];                                                          \
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];                                                     \
    [invocation setTarget:object];                                                                                                         \
    [invocation setSelector:selectors];                                                                                                    \
    int index = 2;                                                                                                                         \
    for (id value in ARRAY_FROM_ARGS(__VA_ARGS__)) {                                                                                                            \
      void *values = (__bridge void *)value;                                                                                               \
      [invocation setArgument:&values atIndex:index++];                                                                                    \
    }                                                                                                                                      \
    [invocation retainArguments];                                                                                                          \
    [invocation invoke];                                                                                                                   \
    invocation;                                                                                                                            \
  })

#define MS_DISPATCH_SELECTOR_OBJECT(type, class, selectorName, ...)                                                                        \
  ({                                                                                                                                       \
    void *results;                                                                                                                         \
    [MS_DISPATCH_SELECTOR(class, selectorName, __VA_ARGS__) getReturnValue:&results];                                            \
    (__bridge type) results;                                                                                                               \
  })

#define MS_DISPATCH_SELECTOR_STRUCT(type, class, selectorName, ...)                                                                        \
  ({                                                                                                                                       \
    void *results = nil;                                                                                                                   \
    [MS_DISPATCH_SELECTOR(class, selectorName, __VA_ARGS__) getReturnValue:&results];                                            \
    (type) results;                                                                                                                        \
  })

@interface MSPerformSelectorUtil : NSObject

+ (void)performSelectorOnMainThread:(NSObject *)source withSelector:(SEL)selector withObjects:(NSObject *)objects, ...;

@end
