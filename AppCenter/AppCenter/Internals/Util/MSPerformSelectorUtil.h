// Licensed under the MIT License.

#import <Foundation/Foundation.h>

#define ARRAY_FROM_ARGS(...)                                                                                                               \
  ({                                                                                                                                       \
    NSMutableArray *initedArray = [NSMutableArray arrayWithObjects:[NSNull null], ##__VA_ARGS__, nil];                                     \
    [initedArray removeObjectAtIndex:0];                                                                                                   \
    initedArray;                                                                                                                           \
  })

#define MS_DISPATCH_SELECTOR_OBJECT(type, class, selectorName, ...)                                                                        \
  ({                                                                                                                                       \
    void *results;                                                                                                                         \
    [MSPerformSelectorUtil performSelectorObject(class, selectorName, ARRAY_FROM_ARGS(__VA_ARGS__)) getReturnValue:&results];                                                      \
    (__bridge type) results;                                                                                                               \
  })

#define MS_DISPATCH_SELECTOR_STRUCT(type, class, selectorName, ...)                                                                        \
  ({                                                                                                                                       \
    void *results = nil;                                                                                                                   \
    [MS_DISPATCH_SELECTOR(class, selectorName, ARRAY_FROM_ARGS(__VA_ARGS__)) getReturnValue:&results];                                                      \
    (type) results;                                                                                                                        \
  })

@interface MSPerformSelectorUtil : NSObject

+ (void)performSelectorOnMainThread:(NSObject *)source withSelector:(SEL)selector withObjects:(NSObject *)objects, ...;

+ (NSInvocation*)performSelectorObject:(NSObject *)source withSelector:(NSString *)selector withObjects:(NSArray *)objects;

+ (NSInvocation*)performSelectorClass:(Class)source withSelector:(NSString *)selector withObjects:(NSArray *)objects;

@end
