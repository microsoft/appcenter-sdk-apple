#import "AVAFile.h"

@implementation AVAFile

- (instancetype)initWithFileId:(NSString *)fileId creationDate:(NSDate *)creationDate {
  if (self = [super init]) {
    _creationDate = creationDate;
    _fileId = fileId;
  }
  return self;
}

@end