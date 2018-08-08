//------------------------------------------------------------------------------
//
// Copyright (c) Microsoft Corporation.
// All rights reserved.
//
// This code is licensed under the MIT License.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files(the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and / or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions :
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//
//------------------------------------------------------------------------------

#import <Foundation/Foundation.h>

@class MSALUser;

@interface MSALResult : NSObject

/*! The Access Token requested. */
@property (readonly) NSString *accessToken;

/*!
    The time that the access token returned in the Token property ceases to be valid.
    This value is calculated based on current UTC time measured locally and the value expiresIn returned from the service
 */
@property (readonly) NSDate *expiresOn;

/*!
    An identifier for the tenant that the token was acquired from. This property will be nil if tenant information is not returned by the service.
 */
@property (readonly) NSString *tenantId;

/*!
    The user object that holds user information.
 */
@property (readonly) MSALUser *user;

/*!
    The raw id token if it's returned by the service or nil if no id token is returned.
*/
@property (readonly) NSString *idToken;

/*!
    The unique id of the user.
 */
@property (readonly) NSString *uniqueId;

/*!
    The scope values returned from the service.
 */
@property (readonly) NSArray<NSString *> *scopes;

@end
