#import <Foundation/Foundation.h>

#if TARGET_OS_OSX
#import <AppKit/AppKit.h>
#import <objc/runtime.h>
#else
#import <UserNotifications/UserNotifications.h>
#endif

#import "MSAppCenterInternal.h"
#import "MSAppDelegateForwarder.h"
#import "MSChannelUnitConfiguration.h"
#import "MSChannelUnitProtocol.h"
#import "MSDataStorage.h"
#import "MSDataStoragePrivate.h"

/**
 * Service storage key name.
 */
static NSString *const kMSServiceName = @"DataStorage";

/**
 * The group ID for storage.
 */
static NSString *const kMSGroupId = @"DataStorage";

/**
 * Singleton.
 */
static MSDataStorage *sharedInstance = nil;
static dispatch_once_t onceToken;

@implementation MSDataStorage

@synthesize channelUnitConfiguration = _channelUnitConfiguration;

#pragma mark - Service initialization

- (instancetype)init {
  if ((self = [super init])) {

  }
  return self;
}
#pragma mark - Service methods


+ (void)readWithPartition:(NSString *)partition documentId:(NSString *)documentId documentType:(Class)documentType completionHandler:(MSDownloadDocumentCompletionHandler)completionHandler {
  (void)partition;
  (void)documentId;
  (void)documentType;
  (void)completionHandler;
}

// List (need optional signature to configure page size)
// The document type (T) must be JSON deserializable
+ (void)readWithPartition:(NSString *)partition documentType:(Class)documentType completionHandler:(MSDownloadDocumentsCompletionHandler)completionHandler {
  (void)partition;
  (void)documentType;
  (void)completionHandler;
}

// Create a document
// The document instance (T) must be JSON serializable
+ (void)createWithPartition:(NSString *)partition documentId:(NSString *)documentId document:(id<NSCoding>)document completionHandler:(MSDownloadDocumentCompletionHandler)completionHandler {
  (void)partition;
  (void)documentId;
  (void)document;
  (void)completionHandler;
}

+ (void)createWithPartition:(NSString *)partition documentId:(NSString *)documentId document:(id<NSCoding>)document conflictResolutionPolicy:(MSCompareAndSwapResolutionCallback *)callback completionHandler:(MSDownloadDocumentCompletionHandler)completionHandler {
  (void)partition;
  (void)documentId;
  (void)document;
  (void)callback;
  (void)completionHandler;
}

// Replace a document
// The document instance (T) must be JSON serializable
+ (void)replaceWithPartition:(NSString *)partition documentId:(NSString *)documentId document:(id<NSCoding>)document completionHandler:(MSDownloadDocumentCompletionHandler)completionHandler {
  (void)partition;
  (void)documentId;
  (void)document;
  (void)completionHandler;
}

+ (void)replaceWithPartition:(NSString *)partition documentId:(NSString *)documentId document:(id<NSCoding>)document conflictResolutionPolicy:(MSCompareAndSwapResolutionCallback *)callback completionHandler:(MSDownloadDocumentCompletionHandler)completionHandler {
  (void)partition;
  (void)documentId;
  (void)document;
  (void)callback;
  (void)completionHandler;
}

// Delete a document
+ (void)deleteDocumentWithPartition:(NSString *)partition documentId:(NSString *)documentId completionHandler:(void (^)(MSDataSourceError* error))completionHandler {
  (void)partition;
  (void)documentId;
  (void)completionHandler;
}

#if TARGET_OS_OSX
- (void)dealloc {
}

#endif

#pragma mark - MSServiceInternal

+ (instancetype)sharedInstance {
  dispatch_once(&onceToken, ^{
    if (sharedInstance == nil) {
      sharedInstance = [self new];
    }
  });
  return sharedInstance;
}

- (void)startWithChannelGroup:(id<MSChannelGroupProtocol>)channelGroup
                    appSecret:(nullable NSString *)appSecret
      transmissionTargetToken:(nullable NSString *)token
              fromApplication:(BOOL)fromApplication {
  [super startWithChannelGroup:channelGroup appSecret:appSecret transmissionTargetToken:token fromApplication:fromApplication];
  MSLogVerbose([MSDataStorage logTag], @"Started Data Storage service.");
}

+ (NSString *)serviceName {
  return kMSServiceName;
}

+ (NSString *)logTag {
  return @"AppCenterDataStorage";
}

- (NSString *)groupId {
  return kMSGroupId;
}

#pragma mark - MSServiceAbstract

- (void)applyEnabledState:(BOOL)isEnabled {
  [super applyEnabledState:isEnabled];
}

@end
