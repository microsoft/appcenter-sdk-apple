// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSDocumentUtils.h"
#import "MSDataStorageConstants.h"

@implementation MSDocumentUtils

+ (NSDictionary *)documentPayloadWithDocumentId:(NSString *)documentId partition:(NSString *)partition document:(NSDictionary *)document {
  return @{kMSDocument : document, kMSPartitionKey : partition, kMSIdKey : documentId};
}

+ (BOOL)isReferenceDictionaryWithKey:(id _Nullable)reference key:(NSString *)key keyType:(Class)keyType {

  // Validate the reference is a dictionary.
  if (!reference || ![(NSObject *)reference isKindOfClass:[NSDictionary class]]) {
    return false;
  }

  // Validate the reference has the expected key.
  NSObject *keyObject = [(NSDictionary *)reference objectForKey:key];
  if (!keyObject) {
    return false;
  }

  // Validate the key object is of the expected type.
  return [keyObject isKindOfClass:keyType];
}

@end
