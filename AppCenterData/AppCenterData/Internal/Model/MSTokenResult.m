// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSTokenResult.h"
#import "MSDataConstants.h"
#import "MSDocumentUtils.h"
#import "MSTokenResultPrivate.h"

@implementation MSTokenResult

@synthesize partition = _partition;
@synthesize dbAccount = _dbAccount;
@synthesize dbName = _dbName;
@synthesize dbCollectionName = _dbCollectionName;
@synthesize token = _token;
@synthesize status = _status;
@synthesize expiresOn = _expiresOn;
@synthesize accountId = _accountId;

- (instancetype)initWithPartition:(NSString *)partition
                        dbAccount:(NSString *)dbAccount
                           dbName:(NSString *)dbName
                 dbCollectionName:(NSString *)dbCollectionName
                            token:(NSString *)token
                           status:(NSString *)status
                        expiresOn:(NSString *)expiresOn
                        accountId:(NSString *_Nullable)accountId {
  self = [super init];
  if (self) {
    _partition = partition;
    _dbAccount = dbAccount;
    _dbName = dbName;
    _dbCollectionName = dbCollectionName;
    _token = token;
    _status = status;
    _expiresOn = expiresOn;
    _accountId = accountId;
  }
  return self;
}

- (instancetype _Nullable)initWithDictionary:(NSDictionary *)token {
  self = [super init];
  if (self) {

    // Instantiate the token.
    self = [[MSTokenResult alloc] initWithPartition:(NSString *)token[kMSPartition]
                                          dbAccount:(NSString *)token[kMSDbAccount]
                                             dbName:(NSString *)token[kMSDbName]
                                   dbCollectionName:(NSString *)token[kMSDbCollectionName]
                                              token:(NSString *)token[kMSToken]
                                             status:(NSString *)token[kMSStatus]
                                          expiresOn:(NSString *)token[kMSExpiresOn]
                                          accountId:token[kMSAccountId]];
  }
  return self;
}

- (instancetype _Nullable)initWithString:(NSString *)tokenString {
  self = [super init];
  if (self) {
    NSData *jsonData = [tokenString dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error;
    NSDictionary *jsonDictionary = [NSJSONSerialization JSONObjectWithData:jsonData options:kNilOptions error:&error];
    if (jsonData != nil && error == nil) {
      self = [self initWithDictionary:jsonDictionary];
    } else {
      self = nil;
    }
  }
  return self;
}

- (NSDictionary *)convertToDictionary {
  return @{
    kMSPartition : self.partition,
    kMSDbAccount : self.dbAccount,
    kMSDbName : self.dbName,
    kMSDbCollectionName : self.dbCollectionName,
    kMSToken : self.token,
    kMSStatus : self.status,
    kMSExpiresOn : self.expiresOn,
    kMSAccountId : self.accountId ? self.accountId : [NSNull null]
  };
}

- (NSString *_Nullable)serializeToString {
  NSError *error = nil;
  NSDictionary *dictionary = [self convertToDictionary];
  if ([NSJSONSerialization isValidJSONObject:dictionary]) {
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dictionary options:NSJSONWritingPrettyPrinted error:&error];
    if (!error && jsonData) {
      return (NSString *)[[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    }
  }
  return nil;
}

@end
