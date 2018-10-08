#import "MSTicketCache.h"
#import "MSTestFrameworks.h"

@interface MSTicketCacheTests : XCTestCase

@property(nonatomic) MSTicketCache *sut;

@end

@implementation MSTicketCacheTests

- (void)setUp {
  [super setUp];

  self.sut = [MSTicketCache sharedInstance];
}

- (void)tearDown {
  [super tearDown];

  [self.sut clearCache];
}

- (void)testInitialization {

  // When

  // Then
  XCTAssertNotNil(self.sut);
  XCTAssertEqual([MSTicketCache sharedInstance], [MSTicketCache sharedInstance]);
  XCTAssertNotNil(self.sut.tickets);
  XCTAssertTrue(self.sut.tickets.count == 0);
}

- (void)testAddingTickets {

  // When
  [self.sut setTicket:@"ticket1" forKey:@"ticketKey1"];

  // Then
  XCTAssertTrue(self.sut.tickets.count == 1);

  // When
  [self.sut setTicket:@"ticket2" forKey:@"ticketKey2"];

  // Then
  XCTAssertTrue(self.sut.tickets.count == 2);
  XCTAssertTrue([[self.sut ticketFor:@"ticketKey1"] isEqualToString:@"ticket1"]);
  XCTAssertTrue([[self.sut ticketFor:@"ticketKey2"] isEqualToString:@"ticket2"]);
  XCTAssertNil([self.sut ticketFor:@"foo"]);
}

- (void)testClearingTickets {

  // If
  [self.sut setTicket:@"ticket1" forKey:@"ticketKey1"];
  [self.sut setTicket:@"ticket2" forKey:@"ticketKey2"];
  [self.sut setTicket:@"ticket3" forKey:@"ticketKey3"];

  // When
  [self.sut clearCache];

  // Then
  XCTAssertTrue(self.sut.tickets.count == 0);
}

@end
