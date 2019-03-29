// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#ifndef Header_h
#define Header_h


#endif /* Header_h */


// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

#import "MSDBStorage.h"
#import "MSDataStore.h"

@interface MSLocalDocumentStore : MSDBStorage

-(bool) deleteTableWithPartition:(NSString *)partitionName;

-(void) createTableWithTableName:(NSString *)tableName;

-(bool) saveDocument:(MSDocumentWrapper *) document partition:(NSString *)partitionName writeOptions:(MSWriteOptions *)options;
@end
