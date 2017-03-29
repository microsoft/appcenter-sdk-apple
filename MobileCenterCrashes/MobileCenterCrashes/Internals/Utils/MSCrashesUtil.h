#import <Foundation/Foundation.h>

@interface MSCrashesUtil : NSObject

/**
 * Returns the directory for storing and reading crash reports for this app.
 *
 * @return The directory containing crash reports for this app.
 */
+ (NSURL *)crashesDir;

/**
 * Returns the directory for storing and reading buffered logs. It will be used in case we crash to make sure we don't
 * loose any data.
 *
 * @return The directory containing buffered events for an app
 */
+ (NSURL *)logBufferDir;

/**
 * Generate a filename based on a given MimeType, 
 * the name is a UUID but the extension reflects the type i.e.:1387A633-618E-4322-BD90-C6EAAAD60143.xml.
 *
 * @return A generated filename based on a given MimeType.
 */ +(NSString *)generateFilenameForMimeType : (NSString *)mimeType;

@end
