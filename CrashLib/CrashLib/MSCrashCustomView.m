// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSCrashCustomView.h"

#if TARGET_OS_OSX
#import <Cocoa/Cocoa.h>
#else
#import <UIKit/UIKit.h>
#endif

#if TARGET_OS_OSX
@interface MSCustomView : NSView
#else
@interface MSCustomView : UIView
#endif

@end

@implementation MSCustomView

#if TARGET_OS_OSX
-(void)drawRect:(NSRect)rect {
#else
-(void)drawRect:(CGRect)rect {
#endif
    [super drawRect:rect];
    @throw [NSException exceptionWithName:NSGenericException reason:@"From custom view."
                                 userInfo:@{NSLocalizedDescriptionKey: @"From custom view!"}];
}

@end

@implementation MSCrashCustomView

- (NSString *)category {
  return @"Exceptions";
}

- (NSString *)title {
  return @"Throw Objective-C exception during dwawing custom view";
}

- (NSString *)desc {
  return @"Throw an uncaught Objective-C exception during dwawing custom view.";
}

- (void)crash {
#if TARGET_OS_OSX
    MSCustomView* views = [[MSCustomView new] initWithFrame: CGRectZero];
    [NSApplication.sharedApplication.mainWindow.contentView addSubview:views];
    views.frame = CGRectMake(0, 0, 2000, 2000);
#else
    MSCustomView* views = [[MSCustomView new] initWithFrame: CGRectZero];
    [UIApplication.sharedApplication.keyWindow.rootViewController.view addSubview:views];
    views.frame = CGRectMake(0, 0, 2000, 2000);
#endif
}

@end
