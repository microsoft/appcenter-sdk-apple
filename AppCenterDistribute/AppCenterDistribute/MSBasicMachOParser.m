#import <mach-o/arch.h>
#import <mach-o/fat.h>
#import <mach-o/loader.h>

#import "MSBasicMachOParser.h"
#import "MSDistributeInternal.h"
#import "MSLogger.h"
#import "MSUtility.h"

static NSString *const kMSBigEndianErrorDesc = @"Big-endian file not supported.";
static NSString *const kMSNotMachOErrorDesc = @"File is not a known type of Mach-O file.";
static NSString *const kMSCantReadErrorDescFormat = @"Cannot read data from file %@";

@interface MSBasicMachOParser ()

@property(nonatomic) NSURL *fileURL;

@end

@implementation MSBasicMachOParser

- (instancetype)initWithBundle:(NSBundle *)bundle {
  if (!bundle || !bundle.executableURL) {
    MSLogError([MSDistribute logTag], @"Given bundle is null or doesn't contain a valid executable URL.");
    return nil;
  }
  if ((self = [super init])) {
    _fileURL = bundle.executableURL;
    _uuid = nil;
    [self parse];
  }
  return self;
}

+ (instancetype)machOParserForMainBundle {
  static MSBasicMachOParser *parser = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    parser = [[MSBasicMachOParser alloc] initWithBundle:MS_APP_MAIN_BUNDLE];
  });
  return parser;
}

- (void)parse {
  NSError *error;
  UInt32 magic;
  NSFileHandle *fh = [NSFileHandle fileHandleForReadingFromURL:self.fileURL error:&error];
  if (error) {
    MSLogError([MSDistribute logTag], @"Cannot get file handle for reading: \n\t%@", error.localizedDescription);
    return;
  }
  if (![self readDataFromFile:fh toBuffer:&magic ofLength:sizeof(magic)]) {
    return;
  }

  // Do the magic.
  [fh seekToFileOffset:0];
  switch (magic) {
  case (UInt32)FAT_MAGIC:
  case (UInt32)FAT_CIGAM:

    /*
     * It's not really the cleanest design, but for simplicity we assume this routine will have seeked the fh to the appropriate embedded
     * Mach-O binary for the current arch.
     */
    [self handleFatHeaders:fh];
    break;
  case (UInt32)MH_MAGIC:
  case (UInt32)MH_MAGIC_64:
    break;
  case (UInt32)MH_CIGAM:
  case (UInt32)MH_CIGAM_64:
    MSLogError([MSDistribute logTag], kMSBigEndianErrorDesc);
    return;
  default:
    MSLogError([MSDistribute logTag], kMSNotMachOErrorDesc);
    return;
  }

  struct mach_header header;
  if (![self readDataFromFile:fh toBuffer:&header ofLength:sizeof(struct mach_header)]) {
    return;
  }

  // Validate file.
  if (header.magic == MH_CIGAM || header.magic == MH_CIGAM_64) {
    MSLogError([MSDistribute logTag], kMSBigEndianErrorDesc);
    return;
  }
  if (header.magic != MH_MAGIC && header.magic != MH_MAGIC_64) {
    MSLogError([MSDistribute logTag], kMSNotMachOErrorDesc);
    return;
  }
  const BOOL is64 = (header.magic == MH_MAGIC_64);

  // Pull alignment word.
  if (is64) {
    UInt32 data;
    if (![self readDataFromFile:fh toBuffer:&data ofLength:sizeof(data)]) {
      return;
    }
  }

  // Scan load commands.
  for (UInt32 i = 0; i < header.ncmds; i++) {
    struct load_command lcmd;
    if (![self readDataFromFile:fh toBuffer:&lcmd ofLength:sizeof(lcmd)]) {
      return;
    }
    [fh seekToFileOffset:(fh.offsetInFile - (UInt64)sizeof(struct load_command))];

    // Get the UUID.
    if (lcmd.cmd == LC_UUID) {
      struct uuid_command uuidcmd;
      if (![self readDataFromFile:fh toBuffer:&uuidcmd ofLength:sizeof(uuidcmd)]) {
        return;
      }
      self.uuid = [[NSUUID alloc] initWithUUIDBytes:uuidcmd.uuid];
      return;
    } else {
      [fh seekToFileOffset:(fh.offsetInFile + lcmd.cmdsize)];
    }
  }
}

- (BOOL)readDataFromFile:(NSFileHandle *)fh toBuffer:(void *)buffer ofLength:(NSUInteger)size {
  NSData *data = [fh readDataOfLength:size];
  if (data.length != size) {
    MSLogError([MSDistribute logTag], kMSCantReadErrorDescFormat, fh);
    return NO;
  }
  [data getBytes:buffer length:size];
  return YES;
}

- (void)handleFatHeaders:(NSFileHandle *)fh {
  struct fat_header header;
  if (![self readDataFromFile:fh toBuffer:&header ofLength:sizeof(header)]) {
    return;
  }

  // Could just reverse the validations below, but this is more correct
  UInt32 magic = CFSwapInt32BigToHost(header.magic);
  if (magic == FAT_CIGAM) {
    MSLogError([MSDistribute logTag], kMSBigEndianErrorDesc);
    return;
  }
  if (magic != FAT_MAGIC) {
    MSLogError([MSDistribute logTag], kMSNotMachOErrorDesc);
    return;
  }
  const UInt32 nArch = CFSwapInt32BigToHost(header.nfat_arch);
  const NXArchInfo *myArch = NXGetLocalArchInfo();
  if (!myArch) {
    MSLogError([MSDistribute logTag], @"Cannot get local architecture info.");
    return;
  }

  /*
   * HACK: x86_64h (64-bit Simulator on modern Mac hardware) causes NXFindBestFatArch() to incorrectly select i386 instead of the desired
   * x86_64. This is an Apple bug.
   */
  if (strcmp(myArch->name, "x86_64h") == 0) {
    myArch = NXGetArchInfoFromName("x86_64");
  }

  // These loops might be inefficient that way but it's easier than dealing with pointers.
  struct fat_arch *archs = (struct fat_arch *)malloc(sizeof(struct fat_arch) * nArch);
  for (UInt32 i = 0; i < nArch; i++) {
    struct fat_arch arch;
    if (![self readDataFromFile:fh toBuffer:&arch ofLength:sizeof(arch)]) {
      free(archs);
      return;
    }
    arch.cputype = (cpu_type_t)CFSwapInt32BigToHost(arch.cputype);
    arch.cpusubtype = (cpu_subtype_t)CFSwapInt32BigToHost(arch.cpusubtype);
    arch.offset = CFSwapInt32BigToHost(arch.offset);
    arch.size = CFSwapInt32BigToHost(arch.size);
    arch.align = CFSwapInt32BigToHost(arch.align);
    *(archs + i) = arch;
  }
  const struct fat_arch *p = NXFindBestFatArch(myArch->cputype, myArch->cpusubtype, archs, nArch);
  if (!p) {
    MSLogError([MSDistribute logTag], @"Cannot find the best match fat architecture.");
  } else {
    [fh seekToFileOffset:p->offset];
  }
  free(archs);
}

@end
