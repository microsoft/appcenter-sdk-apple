#import <XCTest/XCTest.h>
#import "MSStartServiceLog.h"
#import "MSDBStorage.h"
#import "MSFileStorage.h"

const int numLogs = 100;
const int numServices = 100;

@interface MSStoragePerfomanceTests : XCTestCase
@end

@interface MSStoragePerfomanceTests()

@property(nonatomic) MSDBStorage *dbStorage;
@property(nonatomic) MSFileStorage *fStorage;

@end

@implementation MSStoragePerfomanceTests

@synthesize dbStorage;
@synthesize fStorage;

- (void)setUp {
  [super setUp];

  self.dbStorage = [MSDBStorage new];
  self.fStorage = [MSFileStorage new];
}

- (void)tearDown {
  // Put teardown code here. This method is called after the invocation of each test method in the class.
  [super tearDown];

  [self.dbStorage deleteLogsForStorageKey:@"anyKey"];
  [self.fStorage deleteLogsForStorageKey:@"anyKey"];
}

#pragma mark - Database storage tests

- (void)testDatabaseWriteShortLogsPerformance {
  NSArray<MSStartServiceLog*>* arrayOfLogs = [self generateLogsWithShortServicesNames:numLogs withNumService:numServices];

  [self measureBlock:^{
    for (MSStartServiceLog *log in arrayOfLogs) {
      [self.dbStorage saveLog:log withStorageKey:@"anyKey"];
    }
  }];
}

- (void)testDatabaseWriteLongLogsPerformance {
  NSArray<MSStartServiceLog*>* arrayOfLogs = [self generateLogsWithLongServicesNames:numLogs withNumService:numServices];

  [self measureBlock:^{
    for (MSStartServiceLog *log in arrayOfLogs) {
      [self.dbStorage saveLog:log withStorageKey:@"anyKey"];
    }
  }];
}

- (void)testDatabaseWriteVeryLongLogsPerformance {
  NSArray<MSStartServiceLog*>* arrayOfLogs = [self generateLogsWithVeryLongServicesNames:numLogs withNumService:numServices];

  [self measureBlock:^{
    for (MSStartServiceLog *log in arrayOfLogs) {
      [self.dbStorage saveLog:log withStorageKey:@"anyKey"];
    }
  }];
}

#pragma mark - File storage tests

- (void)testFileStorageWriteShortLogsPerformance {
  NSMutableArray<MSStartServiceLog*>* arrayOfLogs = [self generateLogsWithShortServicesNames:numLogs withNumService:numServices];

  [self measureBlock:^{
    for (MSStartServiceLog *log in arrayOfLogs) {
      [self.dbStorage saveLog:log withStorageKey:@"anyKey"];
    }
  }];
}

- (void)testFileStorageWriteLongLogsPerformance {
  NSMutableArray<MSStartServiceLog*>* arrayOfLogs = [self generateLogsWithLongServicesNames:numLogs withNumService:numServices];

  [self measureBlock:^{
    for (MSStartServiceLog *log in arrayOfLogs) {
      [self.dbStorage saveLog:log withStorageKey:@"anyKey"];
    }
  }];
}

- (void)testFileStorageWriteVeryLongLogsPerformance {
  NSMutableArray<MSStartServiceLog*>* arrayOfLogs = [self generateLogsWithVeryLongServicesNames:numLogs withNumService:numServices];

  [self measureBlock:^{
    for (MSStartServiceLog *log in arrayOfLogs) {
      [self.dbStorage saveLog:log withStorageKey:@"anyKey"];
    }
  }];
}

#pragma mark - Private

- (NSArray<MSStartServiceLog*>*)generateLogsWithShortServicesNames:(int) numLogs withNumService:(int)numServices  {
  NSMutableArray<MSStartServiceLog*> *dic = [NSMutableArray new];
  for(int i = 0; i < numLogs; ++i) {
    MSStartServiceLog *log = [MSStartServiceLog new];
    log.services = [self generateServicesWithShortNames:numServices];
    [dic addObject:log];
  }
  return dic;
}

- (NSArray<MSStartServiceLog*>*)generateLogsWithLongServicesNames:(int) numLogs withNumService:(int)numServices  {
  NSMutableArray<MSStartServiceLog*> *dic = [NSMutableArray new];
  for(int i = 0; i < numLogs; ++i) {
    MSStartServiceLog *log = [MSStartServiceLog new];
    log.services = [self generateServicesWithLongNames:numServices];
    [dic addObject:log];
  }
  return dic;
}

- (NSArray<MSStartServiceLog*>*)generateLogsWithVeryLongServicesNames:(int) numLogs withNumService:(int)numServices  {
  NSMutableArray<MSStartServiceLog*> *dic = [NSMutableArray new];
  for(int i = 0; i < numLogs; ++i) {
    MSStartServiceLog *log = [MSStartServiceLog new];
    log.services = [self generateServicesWithVeryLongNames:numServices];
    [dic addObject:log];
  }
  return dic;
}

- (NSArray<NSString*>*)generateServicesWithShortNames:(int)numServices {
  NSMutableArray<NSString*> *dic = [NSMutableArray new];
  for(int i = 0; i < numServices; ++i) {
    [dic addObject:[[NSUUID UUID] UUIDString]];
  }
  return dic;
}

- (NSArray<NSString*>*)generateServicesWithLongNames:(int)numServices {
  NSMutableArray<NSString*> *dic = [NSMutableArray new];
  for(int i = 0; i < numServices; ++i) {
    NSString *value = @"";
    for(int j = 0; j < 10; ++j) {
      value = [value stringByAppendingString:[[NSUUID UUID] UUIDString]];
    }
    [dic addObject:value];
  }
  return dic;
}

- (NSArray<NSString*>*)generateServicesWithVeryLongNames:(int)numServices {
  NSMutableArray<NSString*> *dic = [NSMutableArray new];
  for(int i = 0; i < numServices; ++i) {
    NSString *value = @"";
    for(int j = 0; j < 50; ++j) {
      value = [value stringByAppendingString:[[NSUUID UUID] UUIDString]];
    }
    [dic addObject:value];
  }
  return dic;
}

@end
