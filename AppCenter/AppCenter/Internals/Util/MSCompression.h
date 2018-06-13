#import <Foundation/Foundation.h>

@interface MSCompression : NSObject

/**
 * Compress given data using zLib.
 *
 * @param data Data to compress.
 *
 * @return Compressed data.
 */
+ (NSData *)compressData:(NSData *)data;

@end
