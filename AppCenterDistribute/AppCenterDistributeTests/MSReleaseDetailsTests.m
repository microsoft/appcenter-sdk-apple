#import "MSReleaseDetailsPrivate.h"
#import "MSTestFrameworks.h"
#import "MSUtility+Date.h"

@interface MSReleaseDetailsTests : XCTestCase

@end

@implementation MSReleaseDetailsTests

#pragma mark - Tests

- (void)testInitializeWithDictionary {

  // If
  NSString *filename = [[NSBundle bundleForClass:[self class]] pathForResource:@"release_details" ofType:@"json"];
  NSData *data = [NSData dataWithContentsOfFile:filename];
  MSReleaseDetails *details = [[MSReleaseDetails alloc]
      initWithDictionary:[NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil]];

  // Then
  assertThat(details.id, equalTo(@1));
  assertThat(details.status, equalTo(@"available"));
  assertThat(details.appName, equalTo(@"Unit test"));
  assertThat(details.version, equalTo(@"1.0"));
  assertThat(details.shortVersion, equalTo(@"1"));
  assertThat(details.releaseNotes, equalTo(@"This is a release note for test"));
  assertThat(details.provisioningProfileName, equalTo(@"Unit test provisioning profile"));
  assertThat(details.size, equalTo(@1234567));
  assertThat(details.minOs, equalTo(@"8.0"));
  assertThatBool(details.mandatoryUpdate, equalToLong(YES));
  assertThat(details.fingerprint, equalTo(@"b10a8db164e0754105b7a99be72e3fe5"));
  assertThat(details.uploadedAt, equalTo([NSDate dateWithTimeIntervalSince1970:(1483228800)]));
  assertThat(details.downloadUrl, equalTo([NSURL URLWithString:@"https://contoso.com/path/download/filename"]));
  XCTAssertNil(details.appIconUrl);
  assertThat(details.installUrl, equalTo([NSURL URLWithString:@"itms-service://"
                                                              @"?action=download-manifest&url="
                                                              @"contoso.com/release/filename"]));
  assertThat(details.releaseNotesUrl, equalTo([NSURL URLWithString:@"https://contoso.com/path/release/"
                                                                   @"notes?skip_registration=true"]));
  assertThat(details.packageHashes, equalTo(@[ @"buildId1", @"buildId2" ]));
  assertThat(details.distributionGroupId, equalTo(@"1379041b-0de4-471b-a46b-04b4f754684f"));
  assertThat(details.distributionGroups, equalTo(nil));
}

- (void)testSerializeToDictionary {

  // If
  MSReleaseDetails *details = [MSReleaseDetails new];
  details.id = @(1);
  details.status = @"available";
  details.appName = @"Unittest";
  details.version = @"1.0";
  details.shortVersion = @"0";
  details.releaseNotes = @"This is a release note for test";
  details.provisioningProfileName = @"provisioning_profile_name";
  details.size = @(1234567);
  details.minOs = @"iOS 8.0";
  details.mandatoryUpdate = YES;
  details.fingerprint = @"b10a8db164e0754105b7a99be72e3fe5";
  details.uploadedAt = [MSUtility dateFromISO8601:@"2017-01-01T00:00:00.000Z"];
  details.downloadUrl = [NSURL URLWithString:@"https://contoso.com/path/download/filename"];
  details.appIconUrl = [NSURL URLWithString:@"https://contoso.com/path/icon/filename"];
  details.installUrl = [NSURL URLWithString:@"itms-service://"
                                            @"?action=download-manifest&url="
                                            @"contoso.com/release/filename"];
  details.releaseNotesUrl = [NSURL URLWithString:@"https://contoso.com/path/release/notes?skip_registration=true"];
  details.packageHashes = @[ @"buildId1", @"buildId2" ];
  details.distributionGroupId = @"1379041b-0de4-471b-a46b-04b4f754684f";
  details.distributionGroups = @[];

  // When
  NSDictionary *dictionary = [details serializeToDictionary];

  // Then
  XCTAssertTrue([[[MSReleaseDetails alloc] initWithDictionary:dictionary] isEqual:details]);

  // Additional check for downloadUrl which is not compared in isEqual
  assertThat(dictionary[@"download_url"], equalTo(details.downloadUrl.absoluteString));
}

- (void)testIsValid {

  // If
  MSReleaseDetails *details = [MSReleaseDetails new];

  // Then
  XCTAssertFalse([details isValid]);

  // When
  details.id = @1;

  // Then
  XCTAssertFalse([details isValid]);

  // When
  details.downloadUrl = [[NSURL alloc] initWithString:@"https://contoso.com/path/file.ext"];

  // Then
  XCTAssertTrue([details isValid]);
}

- (void)testNullReleaseNotes {

  // If
  NSDictionary *dictionary = @{ @"release_notes" : [NSNull new] };

  // When
  MSReleaseDetails *details = [[MSReleaseDetails alloc] initWithDictionary:[[NSMutableDictionary alloc] initWithDictionary:dictionary]];

  // Then
  XCTAssertNil(details.releaseNotes);
}

- (void)testIsNotEqualToNil {

  // Then
  XCTAssertFalse([[MSReleaseDetails new] isEqual:nil]);
}

@end
