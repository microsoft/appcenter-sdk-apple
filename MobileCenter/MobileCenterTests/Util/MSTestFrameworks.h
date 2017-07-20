#import <Foundation/Foundation.h>

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdocumentation"
#pragma clang diagnostic ignored "-Wdocumentation-deprecated-sync"
#pragma clang diagnostic ignored "-Wdocumentation-unknown-command"
#pragma clang diagnostic ignored "-Wobjc-interface-ivars"

#if TARGET_OS_IOS
#import <OCHamcrestIOS/OCHamcrestIOS.h>
#elif TARGET_OS_OSX
#import <OCHamcrest/OCHamcrest.h>
#else
// OCHamcrest doesn't seem supporting tvOS and watchOS
#endif
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#pragma clang diagnostic pop
