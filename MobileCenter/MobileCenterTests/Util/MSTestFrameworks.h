#import <Foundation/Foundation.h>
#if TARGET_OS_IOS
#import <OCHamcrestIOS/OCHamcrestIOS.h>
#elif TARGET_OS_OSX
#import <OCHamcrest/OCHamcrest.h>
#else
// OCHamcrest doesn't seem supporting tvOS and watchOS
#endif
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>
