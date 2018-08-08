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
#import <MSAL/MSAL.h>

@class MSALResult;
@class MSALUser;
@class MSALTokenRequest;

@interface MSALPublicClientApplication : NSObject

/*!
    When set to YES (default), MSAL will compare the application's authority against well-known URLs
    templates representing well-formed authorities. It is useful when the authority is obtained at
    run time to prevent MSAL from displaying authentication prompts from malicious pages.
 */
@property BOOL validateAuthority;

/*! The authority the application will use to obtain tokens */
@property (readonly) NSURL *authority;

/*! The client ID of the application, this should come from the app developer portal. */
@property (readonly) NSString *clientId;

/*! The redirect URI of the application */
@property (readonly) NSURL *redirectUri;

/*!
    Used to specify query parameters that must be passed to both the authorize and token endpoints
    to target MSAL at a specific test slice & flight. These apply to all requests made by an application.
 */
@property NSDictionary<NSString *, NSString *> *sliceParameters;

/*! Used in logging callbacks to identify what component in the application
    called MSAL. */
@property NSString *component;

/*!
    Initialize a MSALPublicClientApplication with a given clientID
 
    @param  clientId    The clientID of your application, you should get this from the app portal.
    @param  error       The error that occurred creating the application object, if any (optional)
 */
- (id)initWithClientId:(NSString *)clientId
                 error:(NSError * __autoreleasing *)error;

/*!
    Initialize a MSALPublicClientApplication with a given clientID and authority
 
    @param  clientId    The clientID of your application, you should get this from the app portal.
    @param  authority   A URL indicating a directory that MSAL can use to obtain tokens. In Azure AD
                        it is of the form https://<instance/<tenant>, where <instance> is the
                        directory host (e.g. https://login.microsoftonline.com) and <tenant> is a
                        identifier within the directory itself (e.g. a domain associated to the
                        tenant, such as contoso.onmicrosoft.com, or the GUID representing the
                        TenantID property of the directory)
    @param  error       The error that occurred creating the application object, if any, if you're
                        not interested in the specific error pass in nil.
 */
- (id)initWithClientId:(NSString *)clientId
             authority:(NSString *)authority
                 error:(NSError * __autoreleasing *)error;

/*!
    Returns an array of users visible to this application
 
    @param  error   The error that occured trying to retrieve users, if any, if you're
                    not interested in the specific error pass in nil.
 */
- (NSArray <MSALUser *> *)users:(NSError * __autoreleasing *)error;

/*!
    Returns a specific user for the identifier given (received from a user object returned
    in a previous acquireToken call)
 
    @param  error   The error that occured trying to the user, if any, if you're
                    not interested in the specific error pass in nil.
 */
- (MSALUser *)userForIdentifier:(NSString *)identifier
                          error:(NSError * __autoreleasing *)error;

#pragma SafariViewController Support

/*!
    Ask MSAL to handle a URL response.
    
    @param   response   URL response from your application delegate's openURL handler into
                        MSAL for web authentication sessions
    @return  YES if URL is a response to a MSAL web authentication session and handled,
             NO otherwise.
 */
+ (BOOL)handleMSALResponse:(NSURL *)response;

/*!
    Cancels any currently running interactive web authentication session, resulting
    in the SafariViewController being dismissed and the acquireToken request ending
    in a cancelation error.
 */
+ (void)cancelCurrentWebAuthSession;

#pragma mark -
#pragma mark acquireToken

/*!
    Acquire a token for a new user using interactive authentication
 
    @param  scopes          Permissions you want included in the access token received
                            in the result in the completionBlock. Not all scopes are
                            gauranteed to be included in the access token returned.
    @param  completionBlock The completion block that will be called when the authentication
                            flow completes, or encounters an error.
 */
- (void)acquireTokenForScopes:(NSArray<NSString *> *)scopes
              completionBlock:(MSALCompletionBlock)completionBlock;

#pragma mark -
#pragma mark acquireToken using Login Hint


/*!
    Acquire a token for a new user using interactive authentication
 
    @param  scopes          Permissions you want included in the access token received
                            in the result in the completionBlock. Not all scopes are
                            gauranteed to be included in the access token returned.
    @param  loginHint       A loginHint (usually an email) to pass to the service at the
                            beginning of the interactive authentication flow. The user returned
                            in the completion block is not guaranteed to match the loginHint.
    @param  completionBlock The completion block that will be called when the authentication
                            flow completes, or encounters an error.
 */
- (void)acquireTokenForScopes:(NSArray<NSString *> *)scopes
                    loginHint:(NSString *)loginHint
              completionBlock:(MSALCompletionBlock)completionBlock;

/*!
    Acquire a token for a new user using interactive authentication
 
    @param  scopes          Permissions you want included in the access token received
                            in the result in the completionBlock. Not all scopes are
                            gauranteed to be included in the access token returned.
    @param  loginHint       A loginHint (usually an email) to pass to the service at the
                            beginning of the interactive authentication flow. The user returned
                            in the completion block is not guaranteed to match the loginHint.
    @param  uiBehavior      A specific UI behavior for the interactive authentication flow
    @param  extraQueryParameters    Key-value pairs to pass to the authentication server during
                                    the interactive authentication flow.
    @param  completionBlock The completion block that will be called when the authentication
                            flow completes, or encounters an error.
 */
- (void)acquireTokenForScopes:(NSArray<NSString *> *)scopes
                    loginHint:(NSString *)loginHint
                   uiBehavior:(MSALUIBehavior)uiBehavior
         extraQueryParameters:(NSDictionary <NSString *, NSString *> *)extraQueryParameters
              completionBlock:(MSALCompletionBlock)completionBlock;

/*!
    Acquire a token for a new user using interactive authentication
 
    @param  scopes                  Permissions you want included in the access token received
                                    in the result in the completionBlock. Not all scopes are
                                    gauranteed to be included in the access token returned.
    @param  extraScopesToConsent    Permissions you want the user to consent to in the same
                                    authentication flow, but won't be included in the returned
                                    access token
    @param  loginHint               A loginHint (usually an email) to pass to the service at the
                                    beginning of the interactive authentication flow. The user returned
                                    in the completion block is not guaranteed to match the loginHint.
    @param  uiBehavior              A UI behavior for the interactive authentication flow
    @param  extraQueryParameters    Key-value pairs to pass to the authentication server during
                                    the interactive authentication flow.
    @param  authority               A URL indicating a directory that MSAL can use to obtain tokens. Azure AD
                                    it is of the form https://<instance/<tenant>, where <instance> is the
                                    directory host (e.g. https://login.microsoftonline.com) and <tenant> is a
                                    identifier within the directory itself (e.g. a domain associated to the
                                    tenant, such as contoso.onmicrosoft.com, or the GUID representing the
                                    TenantID property of the directory)
    @param  correlationId           UUID to correlate this request with the server
    @param  completionBlock         The completion block that will be called when the authentication
                                    flow completes, or encounters an error.
 */
- (void)acquireTokenForScopes:(NSArray<NSString *> *)scopes
         extraScopesToConsent:(NSArray<NSString *> *)extraScopesToConsent
                    loginHint:(NSString *)loginHint
                   uiBehavior:(MSALUIBehavior)uiBehavior
         extraQueryParameters:(NSDictionary <NSString *, NSString *> *)extraQueryParameters
                    authority:(NSString *)authority
                correlationId:(NSUUID *)correlationId
              completionBlock:(MSALCompletionBlock)completionBlock;

#pragma mark -
#pragma mark acquireToken using User

/*!
    Acquire a token interactively for an existing user. This is typically used after receiving
    a MSALErrorInteractionRequired error.
 
    @param  scopes          Permissions you want included in the access token received
                            in the result in the completionBlock. Not all scopes are
                            gauranteed to be included in the access token returned.
    @param  user            A user object retrieved from the application object that the
                            interactive authentication flow will be locked down to.
    @param  completionBlock The completion block that will be called when the authentication
                            flow completes, or encounters an error.
 */
- (void)acquireTokenForScopes:(NSArray<NSString *> *)scopes
                         user:(MSALUser *)user
              completionBlock:(MSALCompletionBlock)completionBlock;

/*!
    Acquire a token interactively for an existing user. This is typically used after receiving
    a MSALErrorInteractionRequired error.
 
    @param  scopes                  Permissions you want included in the access token received
                                    in the result in the completionBlock. Not all scopes are
                                    gauranteed to be included in the access token returned.
    @param  user                    A user object retrieved from the application object that the
                                    interactive authentication flow will be locked down to.
    @param  uiBehavior              A UI behavior for the interactive authentication flow
    @param  extraQueryParameters    Key-value pairs to pass to the authentication server during
                                    the interactive authentication flow.
    @param  completionBlock         The completion block that will be called when the authentication
                                    flow completes, or encounters an error.
 */
- (void)acquireTokenForScopes:(NSArray<NSString *> *)scopes
                         user:(MSALUser *)user
                   uiBehavior:(MSALUIBehavior)uiBehavior
         extraQueryParameters:(NSDictionary <NSString *, NSString *> *)extraQueryParameters
              completionBlock:(MSALCompletionBlock)completionBlock;

/*!
    Acquire a token interactively for an existing user. This is typically used after receiving
    a MSALErrorInteractionRequired error.
 
    @param  scopes                  Permissions you want included in the access token received
                                    in the result in the completionBlock. Not all scopes are
                                    gauranteed to be included in the access token returned.
    @param  extraScopesToConsent    Permissions you want the user to consent to in the same
                                    authentication flow, but won't be included in the returned
                                    access token
    @param  user                    A user object retrieved from the application object that the
                                    interactive authentication flow will be locked down to.
    @param  uiBehavior              A UI behavior for the interactive authentication flow
    @param  extraQueryParameters    Key-value pairs to pass to the authentication server during
                                    the interactive authentication flow.
    @param  authority               A URL indicating a directory that MSAL can use to obtain tokens.
                                    Azure AD it is of the form https://<instance/<tenant>, where
                                    <instance> is the directory host
                                    (e.g. https://login.microsoftonline.com) and <tenant> is a
                                    identifier within the directory itself (e.g. a domain associated
                                    to the tenant, such as contoso.onmicrosoft.com, or the GUID
                                    representing the TenantID property of the directory)
    @param  correlationId           UUID to correlate this request with the server
    @param  completionBlock         The completion block that will be called when the authentication
                                    flow completes, or encounters an error.
 */
- (void)acquireTokenForScopes:(NSArray<NSString *> *)scopes
             extraScopesToConsent:(NSArray<NSString *> *)extraScopesToConsent
                         user:(MSALUser *)user
                   uiBehavior:(MSALUIBehavior)uiBehavior
         extraQueryParameters:(NSDictionary <NSString *, NSString *> *)extraQueryParameters
                    authority:(NSString *)authority
                correlationId:(NSUUID *)correlationId
              completionBlock:(MSALCompletionBlock)completionBlock;

#pragma mark -
#pragma mark acquireTokenSilent

/*!
    Acquire a token silently for an existing user.
 
    @param  scopes          Permissions you want included in the access token received
                            in the result in the completionBlock. Not all scopes are
                            gauranteed to be included in the access token returned.
    @param  user            A user object retrieved from the application object that the
                            interactive authentication flow will be locked down to.
    @param  completionBlock The completion block that will be called when the authentication
                            flow completes, or encounters an error.
 */
- (void)acquireTokenSilentForScopes:(NSArray<NSString *> *)scopes
                               user:(MSALUser *)user
                    completionBlock:(MSALCompletionBlock)completionBlock;

/*!
    Acquire a token silently for an existing user.
 
    @param  scopes                  Permissions you want included in the access token received
                                    in the result in the completionBlock. Not all scopes are
                                    gauranteed to be included in the access token returned.
    @param  user                    A user object retrieved from the application object that the
                                    interactive authentication flow will be locked down to.
    @param  authority               A URL indicating a directory that MSAL can use to obtain tokens.
                                    Azure AD it is of the form https://<instance/<tenant>, where
                                    <instance> is the directory host
                                    (e.g. https://login.microsoftonline.com) and <tenant> is a
                                    identifier within the directory itself (e.g. a domain associated
                                    to the tenant, such as contoso.onmicrosoft.com, or the GUID
                                    representing the TenantID property of the directory)
    @param  completionBlock         The completion block that will be called when the authentication
                                    flow completes, or encounters an error.
 */
- (void)acquireTokenSilentForScopes:(NSArray<NSString *> *)scopes
                               user:(MSALUser *)user
                          authority:(NSString *)authority
                    completionBlock:(MSALCompletionBlock)completionBlock;

/*!
    Acquire a token silently for an existing user.
 
    @param  scopes                  Scopes to request from the server, the scopes that come back
                                    can differ from the ones in the original call
    @param  user                    A user object retrieved from the application object that the
                                    interactive authentication flow will be locked down to.
    @param  authority               A URL indicating a directory that MSAL can use to obtain tokens.
                                    Azure AD it is of the form https://<instance/<tenant>, where
                                    <instance> is the directory host
                                    (e.g. https://login.microsoftonline.com) and <tenant> is a
                                    identifier within the directory itself (e.g. a domain associated
                                    to the tenant, such as contoso.onmicrosoft.com, or the GUID
                                    representing the TenantID property of the directory)
    @param  forceRefresh            Ignore any existing access token in the cache and force MSAL to
                                    get a new access token from the service.
    @param  correlationId           UUID to correlate this request with the server
    @param  completionBlock         The completion block that will be called when the authentication
                                    flow completes, or encounters an error.
 */
- (void)acquireTokenSilentForScopes:(NSArray<NSString *> *)scopes
                               user:(MSALUser *)user
                          authority:(NSString *)authority
                       forceRefresh:(BOOL)forceRefresh
                      correlationId:(NSUUID *)correlationId
                    completionBlock:(MSALCompletionBlock)completionBlock;

#pragma mark -
#pragma mark remove user from cache

/*!
    Removes all tokens from the cache for this application for the provided user
 
    @param  user    The user to remove from the cache
 */
- (BOOL)removeUser:(MSALUser *)user
             error:(NSError * __autoreleasing *)error;


@end
