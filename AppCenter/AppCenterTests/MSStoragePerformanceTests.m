#import "MSLogDBStorage.h"
#import "MSStartServiceLog.h"
#import "MSTestFrameworks.h"

static const int kMSNumLogs = 50;
static const int kMSNumServices = 5;
static NSString *const kMSTestGroupId = @"TestGroupId";

@interface MSStoragePerformanceTests : XCTestCase
@end

@interface MSStoragePerformanceTests ()

@property(nonatomic) MSLogDBStorage *dbStorage;

@end

@implementation MSStoragePerformanceTests

@synthesize dbStorage;

- (void)setUp {
  [super setUp];
  self.dbStorage = [MSLogDBStorage new];
}

- (void)tearDown {
  [self.dbStorage deleteLogsWithGroupId:kMSTestGroupId];
  [super tearDown];
}

#pragma mark - Database storage tests

- (void)testDatabaseWriteShortLogsPerformance {
  NSArray<MSStartServiceLog *> *arrayOfLogs = [self generateLogsWithShortServicesNames:kMSNumLogs withNumService:kMSNumServices];
  [self measureBlock:^{
    for (MSStartServiceLog *log in arrayOfLogs) {
      [self.dbStorage saveLog:log withGroupId:kMSTestGroupId flags:MSFlagsDefault];
    }
  }];
}

- (void)testDatabaseWriteLongLogsPerformance {
  NSArray<MSStartServiceLog *> *arrayOfLogs = [self generateLogsWithLongServicesNames:kMSNumLogs withNumService:kMSNumServices];
  [self measureBlock:^{
    for (MSStartServiceLog *log in arrayOfLogs) {
      [self.dbStorage saveLog:log withGroupId:kMSTestGroupId flags:MSFlagsDefault];
    }
  }];
}

- (void)testDatabaseWriteVeryLongLogsPerformance {
  NSArray<MSStartServiceLog *> *arrayOfLogs = [self generateLogsWithVeryLongServicesNames:kMSNumLogs withNumService:kMSNumServices];
  [self measureBlock:^{
    for (MSStartServiceLog *log in arrayOfLogs) {
      [self.dbStorage saveLog:log withGroupId:kMSTestGroupId flags:MSFlagsDefault];
    }
  }];
}

#pragma mark - File storage tests

- (void)testFileStorageWriteShortLogsPerformance {
  NSArray<MSStartServiceLog *> *arrayOfLogs = [self generateLogsWithShortServicesNames:kMSNumLogs withNumService:kMSNumServices];
  [self measureBlock:^{
    for (MSStartServiceLog *log in arrayOfLogs) {
      [self.dbStorage saveLog:log withGroupId:kMSTestGroupId flags:MSFlagsDefault];
    }
  }];
}

- (void)testFileStorageWriteLongLogsPerformance {
  NSArray<MSStartServiceLog *> *arrayOfLogs = [self generateLogsWithLongServicesNames:kMSNumLogs withNumService:kMSNumServices];
  [self measureBlock:^{
    for (MSStartServiceLog *log in arrayOfLogs) {
      [self.dbStorage saveLog:log withGroupId:kMSTestGroupId flags:MSFlagsDefault];
    }
  }];
}

- (void)testFileStorageWriteVeryLongLogsPerformance {
  NSArray<MSStartServiceLog *> *arrayOfLogs = [self generateLogsWithVeryLongServicesNames:kMSNumLogs withNumService:kMSNumServices];
  [self measureBlock:^{
    for (MSStartServiceLog *log in arrayOfLogs) {
      [self.dbStorage saveLog:log withGroupId:kMSTestGroupId flags:MSFlagsDefault];
    }
  }];
}

#pragma mark - Private

- (NSArray<MSStartServiceLog *> *)generateLogsWithShortServicesNames:(int)numLogs withNumService:(int)numServices {
  NSMutableArray<MSStartServiceLog *> *dic = [NSMutableArray new];
  for (int i = 0; i < numLogs; ++i) {
    MSStartServiceLog *log = [MSStartServiceLog new];
    log.services = [self generateServicesWithShortNames:numServices];
    [dic addObject:log];
  }
  return dic;
}

- (NSArray<MSStartServiceLog *> *)generateLogsWithLongServicesNames:(int)numLogs withNumService:(int)numServices {
  NSMutableArray<MSStartServiceLog *> *dic = [NSMutableArray new];
  for (int i = 0; i < numLogs; ++i) {
    MSStartServiceLog *log = [MSStartServiceLog new];
    log.services = [self generateServicesWithLongNames:numServices];
    [dic addObject:log];
  }
  return dic;
}

- (NSArray<MSStartServiceLog *> *)generateLogsWithVeryLongServicesNames:(int)numLogs withNumService:(int)numServices {
  NSMutableArray<MSStartServiceLog *> *dic = [NSMutableArray new];
  for (int i = 0; i < numLogs; ++i) {
    MSStartServiceLog *log = [MSStartServiceLog new];
    log.services = [self generateServicesWithVeryLongNames:numServices];
    [dic addObject:log];
  }
  return dic;
}

- (NSArray<NSString *> *)generateServicesWithShortNames:(int)numServices {
  NSMutableArray<NSString *> *dic = [NSMutableArray new];
  for (int i = 0; i < numServices; ++i) {
    [dic addObject:[[NSUUID UUID] UUIDString]];
  }
  return dic;
}

- (NSArray<NSString *> *)generateServicesWithLongNames:(int)numServices {
  NSMutableArray<NSString *> *dic = [NSMutableArray new];
  for (int i = 0; i < numServices; ++i) {
    NSString *value = @"";
    for (int j = 0; j < 10; ++j) {
      value = [value stringByAppendingString:[[NSUUID UUID] UUIDString]];
    }
    [dic addObject:value];
  }
  return dic;
}

- (NSArray<NSString *> *)generateServicesWithVeryLongNames:(int)numServices {
  NSMutableArray<NSString *> *dic = [NSMutableArray new];
  for (int i = 0; i < numServices; ++i) {
    NSString *value = @"";
    for (int j = 0; j < 50; ++j) {
      value = [value stringByAppendingString:[[NSUUID UUID] UUIDString]];
    }
    [dic addObject:value];
  }
  return dic;
}

@end
