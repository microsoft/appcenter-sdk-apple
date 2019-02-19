
#import <Foundation/Foundation.h>
#import "MSConflictResolutionDelegate.h"
#import "MSDocument.h"

@class Document;

// Conflict resolution policy
@interface MSCompareAndSwapResolutionCallback<T : id<NSCoding>> : NSObject


+ (MSCompareAndSwapResolutionCallback<T> *)compareAndSwapPolicyWithDocument;


// Return the "compare and swap" policy
// The write operation will only be accepted by the server, if the local document
// that was previously read is still currently the one the server knows
// about (i.e. if its etag matches)
+ (MSCompareAndSwapResolutionCallback<T> *)compareAndSwapPolicyWithEtag:(NSString *)etag;

// Same as above, but provide a callback to resolve conflicts in case
// the server rejects an operation
+ (MSCompareAndSwapResolutionCallback<T> *)conflictResolutionPolicyWithEtag:(NSString *)etag delegate:(id<MSConflictResolutionDelegate>)delgate;

@end
