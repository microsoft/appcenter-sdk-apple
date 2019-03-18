#import "MSDataStoreErrors.h"
#import "MSDataStorageConstants.h"
#import "MSDocumentUtils.h"

@implementation MSDocumentUtils

+ (NSDictionary *)documentPayloadWithDocumentId:(NSString *)documentId partition:(NSString *)partition document:(NSDictionary *)document {
  return @{kMSDocument : document, kMSPartitionKey : partition, kMSIdKey : documentId};
}

+ (void)validateSerializationWithDocument:(MSAbstractDocument *)document error:(NSError * _Nullable *)error {
  
  // Validate serialization.
  if (![MSDocumentUtils checkIfObject:document overridesSelector:@selector(serializeToDictionary)]) {
    NSDictionary *userInfo = @{NSLocalizedDescriptionKey : kMSACDocumentSerializationErrorCodeDesc};
    (*error) = [NSError errorWithDomain:kMSACDataStoreErrorDomain code:kMSACDocumentSerializationErrorCode userInfo:userInfo];
    return;
  }
  
  // Validate deserialization.
  if (![MSDocumentUtils checkIfObject:document overridesSelector:@selector(initFromDictionary:)]) {
    NSDictionary *userInfo = @{NSLocalizedDescriptionKey : kMSACDocumentSerializationErrorCodeDesc};
    (*error) = [NSError errorWithDomain:kMSACDataStoreErrorDomain code:kMSACDocumentDeserializationErrorCode userInfo:userInfo];
    return;
  }
}

+ (BOOL)checkIfObject:(NSObject *)object overridesSelector:(SEL)selector {
  Class objSuperClass = [object superclass];
  return [object methodForSelector:selector] != [objSuperClass instanceMethodForSelector:selector];
}

@end
