//
//  SFHFKeychainUtils.m
//
//  Created by Buzz Andersen on 10/20/08.
//  Based partly on code by Jonathan Wight, Jon Crosby, and Mike Malone.
//  Copyright 2008 Sci-Fi Hi-Fi. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person
//  obtaining a copy of this software and associated documentation
//  files (the "Software"), to deal in the Software without
//  restriction, including without limitation the rights to use,
//  copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following
//  conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//  OTHER DEALINGS IN THE SOFTWARE.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

/**
 * Utility class for Keychain.
 */
@interface MSKeychainUtil : NSObject

/**
 * Store a string to Keychain with the given key and service name.
 *
 * @param string A string data to be placed in Keychain.
 * @param key A unique key for the data.
 * @param service A service name for the key.
 * @return YES if stored successfully, NO otherwise.
 */
+ (BOOL)storeString:(NSString *)string forKey:(NSString *)key service:(NSString *)service;

/**
 * Delete a key and a string for the given service name.
 *
 * @param key A unique key for the data.
 * @param service A service name for the key.
 * @return A string data that was deleted.
 */
+ (NSString *)deleteStringForKey:(NSString *)key service:(NSString *)service;

/**
 * Get a string from Keychain with the given key and service name.
 *
 * @param key A unique key for the data.
 * @param service A service name for the key.
 * @return A string data if exists.
 */
+ (NSString *)stringForKey:(NSString *)key service:(NSString *)service;

/**
 * Clear all keys and strings associated with the given service name.
 *
 * @param service A service name for keys.
 * @return YES if cleared successfully, NO otherwise.
 */
+ (BOOL)clearForService:(NSString *)service;

@end
