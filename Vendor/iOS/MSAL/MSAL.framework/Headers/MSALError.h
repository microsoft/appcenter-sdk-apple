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

extern NSString *MSALErrorDomain;

/*!
    The OAuth error returned by the service.
 */
extern NSString *MSALOAuthErrorKey;

/*!
    The suberror returned by the service.
 */
extern NSString *MSALOAuthSubErrorKey;

/*!
    The extded error description. Note that this string can change ands should
    not be relied upon for any error handling logic.
 */
extern NSString *MSALErrorDescriptionKey;

typedef NS_ENUM(NSInteger, MSALErrorCode)
{
    /*!
        A required parameter was not provided, or a passed in parameter was
        invalid. See MSALErrorDescriptionKey for more information.
     */
    MSALErrorInvalidParameter = -42000,
    
    /*!
        The required MSAL URL scheme is not registered in the app's info.plist.
        The scheme should be "msal<clientid>"
     
        e.g. an app with the client ID "abcde-12345-vwxyz-67890" would need to
        register the scheme "msalabcde-12345-vwxyz-67890" and add the
        following to the info.plist file:
     
        <key>CFBundleURLTypes</key>
        <array>
            <dict>
                <key>CFBundleTypeRole</key>
                <string>Editor</string>
                <key>CFBundleURLName</key>
                <string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
                <key>CFBundleURLSchemes</key>
                <array>
                    <string>msalabcde-12345-vwxyz-67890</string>
                </array>
            </dict>

     */
    MSALErrorRedirectSchemeNotRegistered = -42001,
    
    MSALErrorInvalidRequest              = -42002,
    MSALErrorInvalidClient               = -42003,
    
    /*! 
        The passed in authority URL does not pass validation.
        If you're trying to use B2C, you must disable authority validation by
        setting validateAuthority of MSALPublicClientApplication to NO.
     */
    MSALErrorFailedAuthorityValidation = -42004,
    
    /*!
        Interaction required errors occur because of a wide variety of errors
        returned by the authentication service. In all cases the proper response
        is to use a MSAL interactive AcquireToken call with the same parameters.
        For more details check MSALOAuthErrorKey and MSALOAuthErrorDescriptionKey
        in the userInfo dictionary.
     */
    MSALErrorInteractionRequired        = -42100,
    MSALErrorMismatchedUser             = -42101,
    MSALErrorNoAuthorizationResponse    = -42102,
    MSALErrorBadAuthorizationResponse   = -42103,
    MSALErrorUserRequired               = -42104,
    
    /*!
        The user or application failed to authenticate in the interactive flow.
        Inspect MSALOAuthErrorKey and MSALErrorDescriptionKey in the userInfo
        dictionary for more detailed information about the specific error.
     */
    MSALErrorAuthorizationFailed = -42104,
    
    /*!
        MSAL received a valid token response, but it didn't contain an access token.
        Check to make sure your application is consented to get all of the scopes you are asking for.
     */
    MSALErrorNoAccessTokenInResponse = -42105,
    
    /*!
        MSAL encounted an error when trying to store or retrieve items from
        keychain. Inspect NSUnderlyingError from the userInfo dictionary for
        more information about the specific error. Keychain error codes are
        documented in Apple's <Security/SecBase.h> header file
     */
    MSALErrorTokenCacheItemFailure  = -42200,
    MSALErrorAmbiguousAuthority     = -42201,
    MSALErrorUserNotFound           = -42202,
    MSALErrorNoAccessTokensFound    = -42203,
    MSALErrorWrapperCacheFailure    = -42270,
    /*!
        MSAL encounted a network error while trying to authenticate. Inspect
        NSUnderlyingError from the userInfo dictionary for more information
        about the specific error. In most cases the errors will come from the
        system's network layer and the individual errors will be detailed in
        Apple's <Foundation/NSURLError.h> header file.
     */
    MSALErrorNetworkFailure = -42300,
    
    /*!
        The user cancelled the web auth session by tapping the "Done" button on the
        SFSafariViewController.
     */
    MSALErrorUserCanceled = -42400,
    /*!
        The authentication request was cancelled programmatically.
     */
    MSALErrorSessionCanceled = -42401,
    /*!
        An interactive authentication session is already running with the
        SafariViewController visible. Another authentication session can not be
        launched yet.
     */
    MSALErrorInteractiveSessionAlreadyRunning = -42402,
    /*!
        MSAL could not find the current view controller in the view controller
        heirarchy to display the SFSafariViewController on top of.
     */
    MSALErrorNoViewController = -42403,
    
    /*!
        An error ocurred within the MSAL client, inspect the MSALErrorDescriptionKey
        in the userInfo dictionary for more detailed information about the specific
        error.
     */
    MSALErrorInternal = -42500,
    /*!
        The state returned by the server does not match the state that was sent to
        the server at the beginning of the authorization attempt.
     */
    MSALErrorInvalidState = -42501,
    
    /*!
     Response was received in a network call, but the response body was invalid.
     
     e.g. Response was to be expected a key-value pair with "key1" and
     the json response does not contain "key1" elements
     
     */
    MSALErrorInvalidResponse = -42600,
    
};

