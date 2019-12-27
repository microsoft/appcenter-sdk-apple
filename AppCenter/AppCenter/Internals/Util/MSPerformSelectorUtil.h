// Licensed under the MIT License.

#import <Foundation/Foundation.h>

#define ARRAY_FROM_ARGS(...)                                                                                                               \
  ({                                                                                                                                       \
    NSMutableArray *initedArray = [NSMutableArray arrayWithObjects:[NSNull null], ##__VA_ARGS__, nil];                                     \
    [initedArray removeObjectAtIndex:0];                                                                                                   \
    initedArray;                                                                                                                           \
  })

#define MS_DISPATCH_SELECTOR_OBJECT(type, object, selectorName, ...)                                                                       \
  ({                                                                                                                                       \
    void *results;                                                                                                                         \
    [[MSPerformSelectorUtil performSelector:object withSelector:@ #selectorName                                                            \
                                withObjects:ARRAY_FROM_ARGS(__VA_ARGS__)] getReturnValue:&results];                                        \
    (__bridge type) results;                                                                                                               \
  })

#define MS_DISPATCH_SELECTOR_STRUCT(type, object, selectorName, ...)                                                                       \
  ({                                                                                                                                       \
    void *results = nil;                                                                                                                   \
    [[MSPerformSelectorUtil performSelector:object withSelector:@ #selectorName                                                            \
                                withObjects:ARRAY_FROM_ARGS(__VA_ARGS__)] getReturnValue:&results];                                        \
    (type) results;                                                                                                                        \
  })

@interface MSPerformSelectorUtil : NSObject

+ (void)performSelectorOnMainThread:(NSObject *)source withSelector:(SEL)selector withObjects:(NSObject *)objects, ...;

+ (NSInvocation *)performSelector:(id)source withSelector:(NSString *)selector withObjects:(NSArray *)objects;

@end
