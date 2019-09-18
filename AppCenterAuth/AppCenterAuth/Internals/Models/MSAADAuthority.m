// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSAADAuthority.h"

@implementation MSAADAuthority

static NSString *const kMSTypeKey = @"type";

static NSString *const kMSAudienceKey = @"audience";

static NSString *const kMSTenantIdKey = @"tenant_id";

static NSString *const kMSAuthorityCommonUrl = @"https://login.microsoftonline.com/";

static NSString *const kMSSingleTenantAudience = @"AzureADMyOrg";

static NSString *const kMSMultiTenantAudience = @"AzureADMultipleOrgs";

static NSString *const kMSAuthorityTypeAAD = @"AAD";

static NSString *const kMSCommonEndpoint = @"common";

static NSString *const kMSOrganizationsEndpoint = @"organizations";

- (instancetype)initWithDictionary:(NSDictionary *)dictionary {
  if (!dictionary) {
    return nil;
  }
  if ((self = [super initWithDictionary:dictionary])) {
    if (dictionary[kMSAudienceKey]) {
      if ([(NSDictionary *)dictionary[kMSAudienceKey] isKindOfClass:[NSDictionary class]]) {
        NSDictionary *audience = (NSDictionary *)dictionary[kMSAudienceKey];
        NSString *tenantId = (NSString * _Nonnull)audience[kMSTenantIdKey];
        NSString *audienceType = (NSString * _Nonnull)audience[kMSTypeKey];
        NSString *authorityUrlPath = kMSCommonEndpoint;
        if ([audienceType isEqualToString:kMSSingleTenantAudience]) {
          authorityUrlPath = tenantId;
        } else if ([audienceType isEqualToString:kMSMultiTenantAudience]) {
          authorityUrlPath = kMSOrganizationsEndpoint;
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
