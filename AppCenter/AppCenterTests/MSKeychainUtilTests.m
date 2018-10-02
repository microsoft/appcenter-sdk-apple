#import "MSKeychainUtil.h"
#import "MSKeychainUtilPrivate.h"
#import "MSTestFrameworks.h"

@interface MSKeychainUtilTests : XCTestCase
@property(nonatomic) id keychainUtilMock;
@property(nonatomic, copy) NSString *acServiceName;

@end

@implementation MSKeychainUtilTests

- (void)setUp {
  [super setUp];
  self.keychainUtilMock = OCMClassMock([MSKeychainUtil class]);
  self.acServiceName = [NSString stringWithFormat:@"(null).%@", kMSServiceSuffix];
}

- (void)tearDown {
  [super tearDown];
  [self.keychainUtilMock stopMocking];
}

#if !TARGET_OS_TV
- (void)testKeychain {

  // If
  NSString *key = @"Test Key";
  NSString *value = @"Test Value";
  NSDictionary *expectedAddItemQuery = @{
    (__bridge id)kSecAttrService : self.acServiceName,
    (__bridge id)kSecClass : @"genp",
    (__bridge id)kSecAttrAccount : key,
    (__bridge id)kSecValueData : (NSData * _Nonnull)[value dataUsingEncoding:NSUTF8StringEncoding]
  };
  NSDictionary *expectedDeleteItemQuery =
      @{(__bridge id)kSecAttrService : self.acServiceName,
        (__bridge id)kSecClass : @"genp",
        (__bridge id)kSecAttrAccount : key };
  NSDictionary *expectedMatchItemQuery = @{
    (__bridge id)kSecAttrService : self.acServiceName,
    (__bridge id)kSecClass : @"genp",
    (__bridge id)kSecAttrAccount : key,
    (__bridge id)kSecReturnData : (__bridge id)kCFBooleanTrue,
    (__bridge id)kSecMatchLimit : (__bridge id)kSecMatchLimitOne
  };

  // Expect these stubbed calls.
  OCMStub([self.keychainUtilMock addSecItem:[expectedAddItemQuery mutableCopy]]).andReturn(noErr);
  OCMStub([self.keychainUtilMock deleteSecItem:[expectedDeleteItemQuery mutableCopy]]).andReturn(noErr);
  OCMStub([self.keychainUtilMock secItemCopyMatchingQuery:[expectedMatchItemQuery mutableCopy] result:[OCMArg anyPointer]])
      .andReturn(noErr);

  // Reject any other calls.
  OCMReject([self.keychainUtilMock addSecItem:[OCMArg any]]);
  OCMReject([self.keychainUtilMock deleteSecItem:[OCMArg any]]);
  OCMReject([self.keychainUtilMock secItemCopyMatchingQuery:[OCMArg any] result:[OCMArg anyPointer]]);

  // When
  [MSKeychainUtil storeString:value forKey:key];
  [MSKeychainUtil stringForKey:key];
  [MSKeychainUtil deleteStringForKey:key];

  // Then
  OCMVerifyAll(self.keychainUtilMock);
}
#endif

@end
