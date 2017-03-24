#import "MSFile.h"

@implementation MSFile

- (instancetype)initWithURL:(NSURL *)fileURL fileId:(NSString *)fileId creationDate:(NSDate *)creationDate {
  if ((self = [super init])) {
    _fileURL = fileURL;
    _fileId = fileId;
    _creationDate = creationDate;
  }
  return self;
}

@end
