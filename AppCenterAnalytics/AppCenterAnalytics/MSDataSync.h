#import "MSAnalyticsTransmissionTarget.h"
#import "MSServiceAbstract.h"
#import "MSSerializableObject.h"

@interface MSDataStorageError : NSObject
  // TBD
@end



//@interface Document<T : id<NSCoding>> : NSObject
@interface Document<T : id<MSSerializableObject>> : NSObject

+ (NSString *)jsonDocument;

+ (T)document;
+ (void)setDocument:(T)doc;

+ (MSDataStorageError *)error;

+ (NSString *)documentId;
+ (NSString *)etag;
+ (NSDate *)timestamp;

@end


@interface Documents<T : id<MSSerializableObject>> : NSObject

+ (NSArray<Document<T> *> *)documents;

+ (NSArray<T> *)asList;

+ (BOOL)hasNext;

+ (Document<T> *)next;

@end


//typedef void (^MSConflictResolutionAsyncCompletionHandler)(Document<T *> *local, Document<NSString *> *remote);
//
//typedef void (^MSConflictResolutionAsyncCompletionHandler)(Document<T> *local, NSError* error);
//+ (ConflictResolutionPolicy<T> *)firstWriteWinsPolicy:(Document<T> *)localDocument withCompletionHandler:(MSConflictResolutionAsyncCompletionHandler)completionHandler;


@protocol MSConflictResolutionDelegate<MSSerializableObject>

- (id<MSSerializableObject>)resolve:(Document<MSSerializableObject> *)local andRemote:(Document<MSSerializableObject> *)remote;

@end

static NSString *const MSDataStorageUserPartition =  @"/user/%@";
static NSString *const MSDataStorageReadOnlyPartition = @"/readonly";

@interface ConflictResolutionPolicy<T : id<MSSerializableObject>> : NSObject

+ (ConflictResolutionPolicy<T> *)lastWriteWinsPolicy;

+ (ConflictResolutionPolicy<T> *)firstWriteWinsPolicy:(Document<T> *)localDocument;


+ (ConflictResolutionPolicy<T> *)firstWriteWinsPolicy:(Document<T> *)localDocument andConflictResolutionDelegate:(id<MSConflictResolutionDelegate>)delgate;

@end


/**
 * App Center analytics service.
 */
@interface MSDataStorage<T : id<MSSerializableObject>> : MSServiceAbstract

// Read
+ (void)read:(NSString *)partition andDocumentId:(NSString *)documentID andDocumentType:(Class)type completionHandler:(void (^)(Document<T>* document, NSError* error))completionHandler;

// List (need optional signature to configure page size)
+ (void)list:(NSString *)partition andDocumentType:(Class)type completionHandler:(void (^)(Documents<T>* document, NSError* error))completionHandler;


// Create or replace (upsert) a document
+ (void)createOrReplace:(NSString *)partition andDocumentId:(NSString *)documentID andDocument:(T)document completionHandler:(void (^)(Document<T>* document, NSError* error))completionHandler;

+ (void)createOrReplace:(NSString *)partition andDocumentId:(NSString *)documentID andDocument:(T)document withConflictResolutionPolicy:(ConflictResolutionPolicy *)policy completionHandler:(void (^)(Document<T>* document, NSError* error))completionHandler;

// Force replace a document
+ (void)replace:(NSString *)partition andDocumentId:(NSString *)documentID andDocument:(T)document completionHandler:(void (^)(Document<T>* document, NSError* error))completionHandler;

+ (void)replace:(NSString *)partition andDocumentId:(NSString *)documentID andDocument:(T)document withConflictResolutionPolicy:(ConflictResolutionPolicy *)policy completionHandler:(void (^)(Document<T>* document, NSError* error))completionHandler;

// Delete a document
+ (void)deleteDocument:(NSString *)partition andDocumentId:(NSString *)documentID completionHandler:(void (^)(NSError* error))completionHandler;

@end
