// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSAADAuthority.h"
#import "MSAuthConstants.h"

static NSString *const kMSAudienceKey = @"audience";

static NSString *const kMSTenantIdKey = @"tenant_id";

static NSString *const kMSAuthorityCommonUrl = @"https://login.microsoftonline.com/";

static NSString *const kMSSingleTenantAudience = @"AzureADMyOrg";

static NSString *const kMSMultiTenantAudience = @"AzureADMultipleOrgs";

static NSString *const kMSCommonEndpoint = @"common";

static NSString *const kMSOrganizationsEndpoint = @"organizations";

@implementation MSAADAuthority

- (instancetype)initWithDictionary:(NSDictionary *)dictionary {
  if (!dictionary) {
    return nil;
  }
  if ((self = [super initWithDictionary:dictionary])) {
    if (dictionary[kMSAudienceKey]) {
      if ([(NSDictionary *)dictionary[kMSAudienceKey] isKindOfClass:[NSDictionary class]]) {
        NSDictionary *audience = (NSDictionary *)dictionary[kMSAudienceKey];
        NSString *tenantId = (NSString * _Nonnull) audience[kMSTenantIdKey];
        NSString *audienceType = (NSString * _Nonnull) audience[kMSTypeKey];
        NSString *authorityUrlPath = kMSCommonEndpoint;
        if ([audienceType isEqualToString:kMSSingleTenantAudience]) {
          authorityUrlPath = tenantId;
        } else if ([audienceType isEqualToString:kMSMultiTenantAudience]) {
          authorityUrlPath = kMSOrganizationsEndpoint;
        }
        self.authorityUrl = [NSString stringWithFormat:@"%@%@", kMSAuthorityCommonUrl, authorityUrlPath];
      }
    }
  }
  return self;
}

- (BOOL)isValidType {
  return [self.type isEqualToString:kMSAuthorityTypeAAD];
}

@end
