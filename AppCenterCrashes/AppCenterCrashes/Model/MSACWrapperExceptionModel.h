// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

#import "MSACExceptionModel.h"
#import "MSACWrapperExceptionModel.h"

#if __has_include(<AppCenter/MSACSerializableObject.h>)
#import <AppCenter/MSACSerializableObject.h>
#else
#import "MSACSerializableObject.h"
#endif

@interface MSACWrapperExceptionModel : MSACExceptionModel

/*
 * Inner exceptions of this exception [optional].
 */
@property(nonatomic) NSArray<MSACWrapperExceptionModel *> *innerExceptions;

/*
 * Name of the wrapper SDK that emitted this exception.
 * Consists of the name of the SDK and the wrapper platform, e.g. "appcenter.xamarin", "hockeysdk.cordova" [optional].
 */
@property(nonatomic, copy) NSString *wrapperSdkName;

@end
