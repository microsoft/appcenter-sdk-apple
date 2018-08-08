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

@class MSALIdToken;
@class MSALClientInfo;

@interface MSALUser : NSObject <NSCopying>

/*!
    The displayable value in UserPrincipleName(UPN) format. Can be nil if not returned from the service.
 */
@property (readonly) NSString *displayableId;

/*!
    The given name of the user. Can be nil if not returned by the service.
 */
@property (readonly) NSString *name;

/*!
    The identity provider of the user authenticated. Can be nil if not returned by the service.
 */
@property (readonly) NSString *identityProvider;

/*!
    Unique identifier of the user. Can be nil if not returned by the service.
 */
@property (readonly) NSString *uid;

/*!
    Unique tenant identifier of the user. Can be nil if not returned by the service.
 */
@property (readonly) NSString *utid;

/*!
    Host part of the authority string used for authentication.
 */
@property (readonly) NSString *environment;

/*!
    Initialize a MSALUser by extracting information from id token and client info.
 
    @param  idToken             A MSALIdToken object that holds information extracted from the raw id token
    @param  clientInfo          Client info returned by the service
    @param  environment         Host part of the authority string
 */
- (id)initWithIdToken:(MSALIdToken *)idToken
           clientInfo:(MSALClientInfo *)clientInfo
          environment:(NSString *)environment;

/*!
    Initialize a MSALUser with given information
 
    @param  displayableId       The displayable value in UserPrincipleName(UPN) format
    @param  name                The given name of the user
    @param  identityProvider    The identity provider of the user authenticated
    @param  uid                 Unique identifier of the user
    @param  utid                Unique tenant identifier of the user
    @param  environment         Host part of the authority string
 */
- (id)initWithDisplayableId:(NSString *)displayableId
                       name:(NSString *)name
           identityProvider:(NSString *)identityProvider
                        uid:(NSString *)uid
                       utid:(NSString *)utid
                environment:(NSString *)environment;

/*!
    Returns the unique identifier of the user, which is a combination of uid and utid properties
 */
- (NSString *)userIdentifier;

@end
