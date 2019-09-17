// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSAADAuthority.h"
#import "../Util/MSAuthConstants.h"

@implementation MSAADAuthority

static NSString *const kMSAudienceType = @"type";

static NSString *const kMSDefault = @"default";

static NSString *const kMSAuthorityUrl = @"authority_url";

static NSString *const kMSAudience = @"audience";

static NSString *const kMSTenantId = @"tenant_id";

static NSString *const kMSAuthorityCommonUrl = @"https://login.microsoftonline.com/";

static NSString *const kMSSingleTenantAudience = @"AzureADMyOrg";

static NSString *const kMSMultiTenantAudience = @"AzureADMultipleOrgs";

static NSString *const kMSCommonAudience = @"AzureADandPersonalMicrosoftAccount";

- (instancetype)initWithDictionary:(NSDictionary *)dictionary {
  if (!dictionary) {
    return nil;
  }
  if((self = [super initWithDictionary:dictionary])){
    if (dictionary[kMSAudience]) {
      if ([(NSDictionary *)dictionary[kMSAudience] isKindOfClass:[NSDictionary class]]) {
        NSDictionary *audience = (NSDictionary *)dictionary[kMSAudience];
        NSString *tenantId = (NSString * _Nonnull)audience[kMSTenantId];
        NSString *audienceType = (NSString * _Nonnull)audience[kMSAudienceType];
        NSString *authorityUrlPath = @"common";
        if (audienceType == kMSSingleTenantAudience) {
          authorityUrlPath = tenantId;
        } else if (audienceType == kMSMultiTenantAudience) {
          authorityUrlPath = @"organizations";
        }
        NSString *authorityUrl = [NSString stringWithFormat:@"%@%@", kMSAuthorityCommonUrl, authorityUrlPath];
        self.authorityUrl = (NSURL * _Nonnull)[NSURL URLWithString:authorityUrl];
      }
    }
  }
  if (![self isValid]) {
    return nil;
  }
  return self;
}

- (BOOL)isValid {
  return [super isValid] && [self.type isEqualToString:kMSAuthorityTypeAAD];
}

@end
