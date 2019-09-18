// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSAADAuthority.h"

@implementation MSAADAuthority

static NSString *const kMSAudienceType = @"type";

static NSString *const kMSAuthorityUrl = @"authority_url";

static NSString *const kMSAudience = @"audience";

static NSString *const kMSTenantId = @"tenant_id";

static NSString *const kMSAuthorityCommonUrl = @"https://login.microsoftonline.com/";

static NSString *const kMSSingleTenantAudience = @"AzureADMyOrg";

static NSString *const kMSMultiTenantAudience = @"AzureADMultipleOrgs";

static NSString *const kMSCommonAudience = @"AzureADandPersonalMicrosoftAccount";

static NSString *const kMSAuthorityTypeAAD = @"AAD";

static NSString *const kMSCommon = @"common";

static NSString *const kMSorganizations = @"organizations";
- (instancetype)initWithDictionary:(NSDictionary *)dictionary {
  if (!dictionary) {
    return nil;
  }
  if ((self = [super initWithDictionary:dictionary])) {
    if (dictionary[kMSAudience]) {
      if ([(NSDictionary *)dictionary[kMSAudience] isKindOfClass:[NSDictionary class]]) {
        NSDictionary *audience = (NSDictionary *)dictionary[kMSAudience];
        NSString *tenantId = (NSString * _Nonnull)audience[kMSTenantId];
        NSString *audienceType = (NSString * _Nonnull)audience[kMSAudienceType];
        NSString *authorityUrlPath = @"common";
        if ([audienceType isEqualToString:kMSSingleTenantAudience]) {
          authorityUrlPath = tenantId;
        } else if ([audienceType isEqualToString:kMSMultiTenantAudience]) {
          authorityUrlPath = kMSorganizations;
        }
        NSString *authorityUrl = [NSString stringWithFormat:@"%@%@", kMSAuthorityCommonUrl, authorityUrlPath];
        self.authorityUrl = (NSURL * _Nonnull)[NSURL URLWithString:authorityUrl];
      }
    }
  }
  return self;
}

- (BOOL)isValidType {
  return [self.type isEqualToString:kMSAuthorityTypeAAD];
}

@end
