//
//  UserSettings.m
//  SasquatchObjC
//
//  Created by Mehrdad Mozafari on 2/19/19.
//  Copyright © 2019 Microsoft Corp. All rights reserved.
//

#import "UserSettings.h"

@implementation UserSettings

- (instancetype)initWithUserId:(NSString *)userId
                         email:(NSString *)email
                    dictionary:(NSDictionary *)dictionary {
  
  if (self = [super init]) {
    _userId = userId;
    _email = email;
    _dictionary = dictionary;
  }
  return self;
}

- (NSDictionary *)serializeToDictionary {
  return @{@"userId" : _userId ,
           @"email" : _email,
           @"dictionary" : _dictionary
           };
}

- (instancetype)initFromDictionary:(NSDictionary *)dictionary {
  if (self = [super init]) {
    _userId = dictionary[@"userId"];
    _email = dictionary[@"email"];
    _dictionary = dictionary[@"dictionary"];
  }
  return self;
}

@end
