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
@class MSALAccount;
@class MSALTokenRequest;
@class MSALAuthority;
@class WKWebView;

@interface MSALPublicClientApplication : NSObject

/*!
    When set to YES (default), MSAL will compare the application's authority against well-known URLs
    templates representing well-formed authorities. It is useful when the authority is obtained at
    run time to prevent MSAL from displaying authentication prompts from malicious pages.
 */
@property BOOL validateAuthority;

/*! Enable to return access token with extended lifttime during server outage. */
@property BOOL extendedLifetimeEnabled;

/*! The authority the application will use to obtain tokens */
@property (readonly, nonnull) MSALAuthority *authority;

/*! The client ID of the application, this should come from the app developer portal. */
@property (readonly, nonnull) NSString *clientId;

/*! The redirect URI of the application */
@property (readonly, nonnull) NSString *redirectUri;

/*! When checking an access token for expiration we check if time to expiration
 is less than this value (in seconds) before making the request. The goal is to
 refresh the token ahead of its expiration and also not to return a token that is
 about to expire. */
@property NSUInteger expirationBuffer;

/*!
    Used to specify query parameters that must be passed to both the authorize and token endpoints
    to target MSAL at a specific test slice & flight. These apply to all requests made by an application.
 */
@property (nullable) NSDictionary<NSString *, NSString *> *sliceParameters;

/*! Used in logging callbacks to identify what component in the application
    called MSAL. */
@property (nullable) NSString *component;

/*! The webview selection to be used for authentication.
 By default, it is going to use the following to authenticate.
 - iOS: SFAuthenticationSession for iOS11 and up, SFSafariViewController otherwise.
 - macOS:  WKWebView
 */
@property MSALWebviewType webviewType;

/*! Passed in webview to display web content when webviewSelection is set to MSALWebviewTypeWKWebView.
    For iOS, this will be ignored if MSALWebviewTypeSystemDefault is chosen. */
@property (nullable) WKWebView *customWebview;

/*!
    Initialize a MSALPublicClientApplication with a given clientID
 
    @param  clientId    The clientID of your application, you should get this from the app portal.
    @param  error       The error that occurred creating the application object, if any (optional)
 */
- (nullable instancetype)initWithClientId:(nonnull NSString *)clientId
                                    error:(NSError * _Nullable __autoreleasing * _Nullable)error;

/*!
    Initialize a MSALPublicClientApplication with a given clientID and authority
 
    @param  clientId    The clientID of your application, you should get this from the app portal.
    @param  authority   Authority indicating a directory that MSAL can use to obtain tokens. In Azure AD
                        it is of the form https://<instance/<tenant>, where <instance> is the
                        directory host (e.g. https://login.microsoftonline.com) and <tenant> is a
                        identifier within the directory itself (e.g. a domain associated to the
                        tenant, such as contoso.onmicrosoft.com, or the GUID representing the
                        TenantID property of the directory)
    @param  error       The error that occurred creating the application object, if any, if you're
                        not interested in the specific error pass in nil.
 */
- (nullable instancetype)initWithClientId:(nonnull NSString *)clientId
                                authority:(nullable MSALAuthority *)authority
                                    error:(NSError * _Nullable __autoreleasing * _Nullable)error;

/*!
 Initialize a MSALPublicClientApplication with a given clientID, authority and redirectUri

 @param  clientId       The clientID of your application, you should get this from the app portal.
 @param  authority      Authority indicating a directory that MSAL can use to obtain tokens. In Azure AD
                        it is of the form https://<instance/<tenant>, where <instance> is the
                        directory host (e.g. https://login.microsoftonline.com) and <tenant> is a
                        identifier within the directory itself (e.g. a domain associated to the
                        tenant, such as contoso.onmicrosoft.com, or the GUID representing the
                        TenantID property of the directory)
 @param  redirectUri    The redirect URI of the application
 @param  error          The error that occurred creating the application object, if any, if you're
                        not interested in the specific error pass in nil.
 */
- (nullable instancetype)initWithClientId:(nonnull NSString *)clientId
                                authority:(nullable MSALAuthority *)authority
                              redirectUri:(nullable NSString *)redirectUri
                                    error:(NSError * _Nullable __autoreleasing * _Nullable)error;


#if TARGET_OS_IPHONE
/*!
 The keychain sharing group to use for the token cache.
 If it is nil, default MSAL group will be used.
 */
@property (nonatomic, readonly, nullable) NSString *keychainGroup;

/*!
 Initialize a MSALPublicClientApplication with a given clientID and keychain group
 
 @param  clientId       The clientID of your application, you should get this from the app portal.
 @param  keychainGroup  The keychain sharing group to use for the token cache. (optional)
                        If you provide this key, you MUST add the capability to your Application Entilement.
 @param  error          The error that occurred creating the application object, if any (optional)
 */
- (nullable instancetype)initWithClientId:(nonnull NSString *)clientId
                            keychainGroup:(nullable NSString *)keychainGroup
                                    error:(NSError * _Nullable __autoreleasing * _Nullable)error;

/*!
 Initialize a MSALPublicClientApplication with a given clientID, authority and keychain group
 
 @param  clientId       The clientID of your application, you should get this from the app portal.
 @param  keychainGroup  The keychain sharing group to use for the token cache. (optional)
                        If you provide this key, you MUST add the capability to your Application Entilement.
 @param  authority      Authority indicating a directory that MSAL can use to obtain tokens. In Azure AD
                        it is of the form https://<instance/<tenant>, where <instance> is the
                        directory host (e.g. https://login.microsoftonline.com) and <tenant> is a
                        identifier within the directory itself (e.g. a domain associated to the
                        tenant, such as contoso.onmicrosoft.com, or the GUID representing the
                        TenantID property of the directory)
 @param  error          The error that occurred creating the application object, if any, if you're
                        not interested in the specific error pass in nil.
 */
- (nullable instancetype)initWithClientId:(nonnull NSString *)clientId
                            keychainGroup:(nullable NSString *)keychainGroup
                                authority:(nullable MSALAuthority *)authority
                                    error:(NSError * _Nullable __autoreleasing * _Nullable)error;

/*!
 Initialize a MSALPublicClientApplication with a given clientID, authority, keychain group and redirect uri

 @param  clientId       The clientID of your application, you should get this from the app portal.
 @param  keychainGroup  The keychain sharing group to use for the token cache. (optional)
                        If you provide this key, you MUST add the capability to your Application Entilement.
 @param  authority      Authority indicating a directory that MSAL can use to obtain tokens. In Azure AD
                        it is of the form https://<instance/<tenant>, where <instance> is the
                        directory host (e.g. https://login.microsoftonline.com) and <tenant> is a
                        identifier within the directory itself (e.g. a domain associated to the
                        tenant, such as contoso.onmicrosoft.com, or the GUID representing the
                        TenantID property of the directory)
 @param  redirectUri    The redirect URI of the application
 @param  error          The error that occurred creating the application object, if any, if you're
                        not interested in the specific error pass in nil.
 */
- (nullable instancetype)initWithClientId:(nonnull NSString *)clientId
                            keychainGroup:(nullable NSString *)keychainGroup
                                authority:(nullable MSALAuthority *)authority
                              redirectUri:(nullable NSString *)redirectUri
                                    error:(NSError * _Nullable __autoreleasing * _Nullable)error;
#endif

/*!
 Returns an array of all accounts visible to this application.

 @param  error      The error that occured trying to retrieve accounts, if any, if you're
                    not interested in the specific error pass in nil.
 */

- (nullable NSArray <MSALAccount *> *)allAccounts:(NSError * _Nullable __autoreleasing * _Nullable)error;

/*!
 Returns account for for the given home identifier (received from an account object returned in a previous acquireToken call)

 @param  error      The error that occured trying to get the accounts, if any, if you're
                    not interested in the specific error pass in nil.
 */
- (nullable MSALAccount *)accountForHomeAccountId:(nonnull NSString *)homeAccountId
                                            error:(NSError * _Nullable __autoreleasing * _Nullable)error;

/*!
 Returns account for for the given username (received from an account object returned in a previous acquireToken call or ADAL)

 @param  username    The displayable value in UserPrincipleName(UPN) format
 @param  error       The error that occured trying to get the accounts, if any, if you're
                     not interested in the specific error pass in nil.
 */
- (nullable MSALAccount *)accountForUsername:(nonnull NSString *)username
                                       error:(NSError * _Nullable __autoreleasing * _Nullable)error;

/*!
    Returns an array of accounts visible to this application and filtered by authority.
 
    @param  completionBlock     The completion block that will be called when accounts are loaded, or MSAL encountered an error.
 */
- (void)allAccountsFilteredByAuthority:(nonnull MSALAccountsCompletionBlock)completionBlock;

#pragma SafariViewController Support

#if TARGET_OS_IPHONE
/*!
    Ask MSAL to handle a URL response.
    
    @param   response   URL response from your application delegate's openURL handler into
                        MSAL for web authentication sessions
    @return  YES if URL is a response to a MSAL web authentication session and handled,
             NO otherwise.
 */
+ (BOOL)handleMSALResponse:(nonnull NSURL *)response;
#endif

/*!
    Cancels any currently running interactive web authentication session, resulting
    in the SafariViewController being dismissed and the acquireToken request ending
    in a cancelation error.
 */
+ (void)cancelCurrentWebAuthSession;

#pragma mark -
#pragma mark acquireToken

/*!
    Acquire a token for a new account using interactive authentication
 
    @param  scopes          Permissions you want included in the access token received
                            in the result in the completionBlock. Not all scopes are
                            gauranteed to be included in the access token returned.
    @param  completionBlock The completion block that will be called when the authentication
                            flow completes, or encounters an error.
 */
- (void)acquireTokenForScopes:(nonnull NSArray<NSString *> *)scopes
              completionBlock:(nonnull MSALCompletionBlock)completionBlock;

#pragma mark -
#pragma mark acquireToken using Login Hint


/*!
    Acquire a token for a new account using interactive authentication
 
    @param  scopes          Permissions you want included in the access token received
                            in the result in the completionBlock. Not all scopes are
                            gauranteed to be included in the access token returned.
    @param  loginHint       A loginHint (usually an email) to pass to the service at the
                            beginning of the interactive authentication flow. The account returned
                            in the completion block is not guaranteed to match the loginHint.
    @param  completionBlock The completion block that will be called when the authentication
                            flow completes, or encounters an error.
 */
- (void)acquireTokenForScopes:(nonnull NSArray<NSString *> *)scopes
                    loginHint:(nullable NSString *)loginHint
              completionBlock:(nonnull MSALCompletionBlock)completionBlock;

/*!
    Acquire a token for a new account using interactive authentication
 
    @param  scopes          Permissions you want included in the access token received
                            in the result in the completionBlock. Not all scopes are
                            gauranteed to be included in the access token returned.
    @param  loginHint       A loginHint (usually an email) to pass to the service at the
                            beginning of the interactive authentication flow. The account returned
                            in the completion block is not guaranteed to match the loginHint.
    @param  uiBehavior      A specific UI behavior for the interactive authentication flow
    @param  extraQueryParameters    Key-value pairs to pass to the authentication server during
                                    the interactive authentication flow. This should not be url-encoded value.
    @param  completionBlock The completion block that will be called when the authentication
                            flow completes, or encounters an error.
 */
- (void)acquireTokenForScopes:(nonnull NSArray<NSString *> *)scopes
                    loginHint:(nullable NSString *)loginHint
                   uiBehavior:(MSALUIBehavior)uiBehavior
         extraQueryParameters:(nullable NSDictionary <NSString *, NSString *> *)extraQueryParameters
              completionBlock:(nonnull MSALCompletionBlock)completionBlock;

/*!
    Acquire a token for a new account using interactive authentication
 
    @param  scopes                  Permissions you want included in the access token received
                                    in the result in the completionBlock. Not all scopes are
                                    gauranteed to be included in the access token returned.
    @param  extraScopesToConsent    Permissions you want the account to consent to in the same
                                    authentication flow, but won't be included in the returned
                                    access token
    @param  loginHint               A loginHint (usually an email) to pass to the service at the
                                    beginning of the interactive authentication flow. The account returned
                                    in the completion block is not guaranteed to match the loginHint.
    @param  uiBehavior              A UI behavior for the interactive authentication flow
    @param  extraQueryParameters    Key-value pairs to pass to the authentication server during
                                    the interactive authentication flow.
    @param  authority               Authority indicating a directory that MSAL can use to obtain tokens. Azure AD
                                    it is of the form https://<instance/<tenant>, where <instance> is the
                                    directory host (e.g. https://login.microsoftonline.com) and <tenant> is a
                                    identifier within the directory itself (e.g. a domain associated to the
                                    tenant, such as contoso.onmicrosoft.com, or the GUID representing the
                                    TenantID property of the directory)
    @param  correlationId           UUID to correlate this request with the server
    @param  completionBlock         The completion block that will be called when the authentication
                                    flow completes, or encounters an error.
 */
- (void)acquireTokenForScopes:(nonnull NSArray<NSString *> *)scopes
         extraScopesToConsent:(nullable NSArray<NSString *> *)extraScopesToConsent
                    loginHint:(nullable NSString *)loginHint
                   uiBehavior:(MSALUIBehavior)uiBehavior
         extraQueryParameters:(nullable NSDictionary <NSString *, NSString *> *)extraQueryParameters
                    authority:(nullable MSALAuthority *)authority
                correlationId:(nullable NSUUID *)correlationId
              completionBlock:(nonnull MSALCompletionBlock)completionBlock;

#pragma mark -
#pragma mark acquireToken using Account

/*!
    Acquire a token interactively for an existing account. This is typically used after receiving
    a MSALErrorInteractionRequired error.
 
    @param  scopes          Permissions you want included in the access token received
                            in the result in the completionBlock. Not all scopes are
                            gauranteed to be included in the access token returned.
    @param  account         An account object retrieved from the application object that the
                            interactive authentication flow will be locked down to.
    @param  completionBlock The completion block that will be called when the authentication
                            flow completes, or encounters an error.
 */
- (void)acquireTokenForScopes:(nonnull NSArray<NSString *> *)scopes
                      account:(nullable MSALAccount *)account
              completionBlock:(nonnull MSALCompletionBlock)completionBlock;

/*!
    Acquire a token interactively for an existing account. This is typically used after receiving
    a MSALErrorInteractionRequired error.
 
    @param  scopes                  Permissions you want included in the access token received
                                    in the result in the completionBlock. Not all scopes are
                                    gauranteed to be included in the access token returned.
    @param  account                 An account object retrieved from the application object that the
                                    interactive authentication flow will be locked down to.
    @param  uiBehavior              A UI behavior for the interactive authentication flow
    @param  extraQueryParameters    Key-value pairs to pass to the authentication server during
                                    the interactive authentication flow. This should not be url-encoded value.
    @param  completionBlock         The completion block that will be called when the authentication
                                    flow completes, or encounters an error.
 */
- (void)acquireTokenForScopes:(nonnull NSArray<NSString *> *)scopes
                      account:(nullable MSALAccount *)account
                   uiBehavior:(MSALUIBehavior)uiBehavior
         extraQueryParameters:(nullable NSDictionary <NSString *, NSString *> *)extraQueryParameters
              completionBlock:(nonnull MSALCompletionBlock)completionBlock;

/*!
    Acquire a token interactively for an existing account. This is typically used after receiving
    a MSALErrorInteractionRequired error.
 
    @param  scopes                  Permissions you want included in the access token received
                                    in the result in the completionBlock. Not all scopes are
                                    gauranteed to be included in the access token returned.
    @param  extraScopesToConsent    Permissions you want the account to consent to in the same
                                    authentication flow, but won't be included in the returned
                                    access token
    @param  account                 An account object retrieved from the application object that the
                                    interactive authentication flow will be locked down to.
    @param  uiBehavior              A UI behavior for the interactive authentication flow
    @param  extraQueryParameters    Key-value pairs to pass to the authentication server during
                                    the interactive authentication flow.
    @param  authority               Authority indicating a directory that MSAL can use to obtain tokens.
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
- (void)acquireTokenForScopes:(nonnull NSArray<NSString *> *)scopes
         extraScopesToConsent:(nullable NSArray<NSString *> *)extraScopesToConsent
                      account:(nullable MSALAccount *)account
                   uiBehavior:(MSALUIBehavior)uiBehavior
         extraQueryParameters:(nullable NSDictionary <NSString *, NSString *> *)extraQueryParameters
                    authority:(nullable MSALAuthority *)authority
                correlationId:(nullable NSUUID *)correlationId
              completionBlock:(nonnull MSALCompletionBlock)completionBlock;

/*!
 Acquire a token interactively for an existing account. This is typically used after receiving
 a MSALErrorInteractionRequired error.
 
 @param  scopes                  Permissions you want included in the access token received
                                 in the result in the completionBlock. Not all scopes are
                                 gauranteed to be included in the access token returned.
 @param  extraScopesToConsent    Permissions you want the account to consent to in the same
                                 authentication flow, but won't be included in the returned
                                 access token
 @param  account                 An account object retrieved from the application object that the
                                 interactive authentication flow will be locked down to.
 @param  uiBehavior              A UI behavior for the interactive authentication flow
 @param  extraQueryParameters    Key-value pairs to pass to the authentication server during
                                 the interactive authentication flow. This should not be url-encoded value.
 @param  claims                  The claims parameter that needs to be sent to authorization endpoint.
 @param  authority               Authority indicating a directory that MSAL can use to obtain tokens.
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
- (void)acquireTokenForScopes:(nonnull NSArray<NSString *> *)scopes
         extraScopesToConsent:(nullable NSArray<NSString *> *)extraScopesToConsent
                      account:(nullable MSALAccount *)account
                   uiBehavior:(MSALUIBehavior)uiBehavior
         extraQueryParameters:(nullable NSDictionary <NSString *, NSString *> *)extraQueryParameters
                       claims:(nullable NSString *)claims
                    authority:(nullable MSALAuthority *)authority
                correlationId:(nullable NSUUID *)correlationId
              completionBlock:(nonnull MSALCompletionBlock)completionBlock;

#pragma mark -
#pragma mark acquireTokenSilent

/*!
    Acquire a token silently for an existing account.
 
    @param  scopes          Permissions you want included in the access token received
                            in the result in the completionBlock. Not all scopes are
                            gauranteed to be included in the access token returned.
    @param  account         An account object retrieved from the application object that the
                            interactive authentication flow will be locked down to.
    @param  completionBlock The completion block that will be called when the authentication
                            flow completes, or encounters an error.
 */
- (void)acquireTokenSilentForScopes:(nonnull NSArray<NSString *> *)scopes
                            account:(nonnull MSALAccount *)account
                    completionBlock:(nonnull MSALCompletionBlock)completionBlock;

/*!
    Acquire a token silently for an existing account.
 
    @param  scopes                  Permissions you want included in the access token received
                                    in the result in the completionBlock. Not all scopes are
                                    gauranteed to be included in the access token returned.
    @param  account                 An account object retrieved from the application object that the
                                    interactive authentication flow will be locked down to.
    @param  authority               Authority indicating a directory that MSAL can use to obtain tokens.
                                    Azure AD it is of the form https://<instance/<tenant>, where
                                    <instance> is the directory host
                                    (e.g. https://login.microsoftonline.com) and <tenant> is a
                                    identifier within the directory itself (e.g. a domain associated
                                    to the tenant, such as contoso.onmicrosoft.com, or the GUID
                                    representing the TenantID property of the directory)
    @param  completionBlock         The completion block that will be called when the authentication
                                    flow completes, or encounters an error.
 */
- (void)acquireTokenSilentForScopes:(nonnull NSArray<NSString *> *)scopes
                            account:(nonnull MSALAccount *)account
                          authority:(nullable MSALAuthority *)authority
                    completionBlock:(nonnull MSALCompletionBlock)completionBlock;

/*!
    Acquire a token silently for an existing account.
 
    @param  scopes                  Scopes to request from the server, the scopes that come back
                                    can differ from the ones in the original call
    @param  account                 An account object retrieved from the application object that the
                                    interactive authentication flow will be locked down to.
    @param  authority               Authority indicating a directory that MSAL can use to obtain tokens.
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
- (void)acquireTokenSilentForScopes:(nonnull NSArray<NSString *> *)scopes
                            account:(nonnull MSALAccount *)account
                          authority:(nullable MSALAuthority *)authority
                       forceRefresh:(BOOL)forceRefresh
                      correlationId:(nullable NSUUID *)correlationId
                    completionBlock:(nonnull MSALCompletionBlock)completionBlock;

#pragma mark -
#pragma mark remove account from cache

/*!
    Removes all tokens from the cache for this application for the provided account
    User will need to enter his credentials again after calling this API
 
    @param  account    The account to remove from the cache
 */
- (BOOL)removeAccount:(nonnull MSALAccount *)account
                error:(NSError * _Nullable __autoreleasing * _Nullable)error;


@end
