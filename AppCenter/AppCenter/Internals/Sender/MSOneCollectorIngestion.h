#import "MSHttpSender.h"

static NSString *const kMSApiVersion = @"1.0";
static NSString *const kMSApiPath = @"/OneCollector";
static NSString *const kMSOneCollectorContentType = @"application/x-json-stream; charset=utf-8;";
static NSString *const kMSApiKey = @"apikey";
static NSString *const kMSClientVersionKey = @"Client-Version";
static NSString *const kMSClientVersionFormat = @"ACT-iOS-ObjectiveC-no-%@-%@"; // TODO confirm value for iOS
static NSString *const kMSUploadTimeKey = @"Upload-Time";

@interface MSOneCollectorIngestion : MSHttpSender

/**
 * Initialize the Sender.
 *
 * @param baseUrl Base url.
 *
 * @return A sender instance.
 */
- (id)initWithBaseUrl:(NSString *)baseUrl;

@end
