#import "MSCustomApplicationDelegate.h"
#import "MSDelegateForwarder.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * Enum used to represent all kind of executors running the completion handler.
 */
typedef NS_OPTIONS(NSUInteger, MSCompletionExecutor) {
  MSCompletionExecutorNone = (1 << 0),
  MSCompletionExecutorOriginal = (1 << 1),
  MSCompletionExecutorCustom = (1 << 2),
  MSCompletionExecutorForwarder = (1 << 3)
};

@interface MSAppDelegateForwarder : MSDelegateForwarder <MSCustomApplicationDelegate>

@end

NS_ASSUME_NONNULL_END
