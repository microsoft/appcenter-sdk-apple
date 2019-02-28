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

@class MSALAccount;
@class MSALAuthority;

@interface MSALResult : NSObject

/*! The Access Token requested. */
@property (readonly, nonnull) NSString *accessToken;

/*!
    The time that the access token returned in the Token property ceases to be valid.
    This value is calculated based on current UTC time measured locally and the value expiresIn returned from the service
 */
@property (readonly, nonnull) NSDate *expiresOn;

/*!
    Some access tokens have extended lifetime when server is in an unavailable state.
    This property indicates whether the access token is returned in such a state.
 */
@property (readonly) BOOL extendedLifeTimeToken;

/*!
    An identifier for the tenant that the token was acquired from. This property will be nil if tenant information is not returned by the service.
 */
@property (readonly, nullable) NSString *tenantId;

/*!
    The account object that holds account information.
 */
@property (readonly, nonnull) MSALAccount *account;

/*!
    The raw id token if it's returned by the service or nil if no id token is returned.
*/
@property (readonly, nullable) NSString *idToken;

/*!
    The unique id of the user.
 */
@property (readonly, nullable) NSString *uniqueId;

/*!
    The scope values returned from the service.
 */
@property (readonly, nonnull) NSArray<NSString *> *scopes;

/*!
 Represents the authority used for getting the token from STS and caching it.
 This authority should be used for subsequent silent requests.
 It will be different from the authority provided by developer for sovereign cloud scenarios.
 */
@property (readonly, nonnull) MSALAuthority *authority;

@end
