//
//  UserSettings.h
//  SasquatchObjC
//
//  Created by Mehrdad Mozafari on 2/19/19.
//  Copyright © 2019 Microsoft Corp. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AppCenterDataStorage.h"
#import "MSSerializableDocument.h"
NS_ASSUME_NONNULL_BEGIN

@interface UserSettings : NSObject<MSSerializableDocument>

@property (nonatomic, strong, readonly) NSString *userId;
@property (nonatomic, strong) NSString *email;
@property (nonatomic, strong) NSDictionary *dictionary;


- (instancetype)initWithUserId:(NSString *)userId
                         email:(NSString *)email
                    dictionary:(NSDictionary *)dictionary;

@end

NS_ASSUME_NONNULL_END
