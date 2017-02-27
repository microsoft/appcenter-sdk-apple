#import <mach-o/arch.h>
#import <mach-o/fat.h>
#import <mach-o/loader.h>

#import "MSBasicMachOParser.h"
#import "MSLogger.h"
#import "MSUpdatesInternal.h"
#import "MSUtil.h"

static NSString *const kMSBigEndianErrorDesc = @"Big-endian file not supported.";
static NSString *const kMSNotMachOErrorDesc = @"File is not a known type of Mach-O file.";
static NSString *const kMSCantReadErrorDescFormat = @"Cannot read data from file %@";

@interface MSBasicMachOParser ()

@property(nonatomic, strong) NSURL *fileURL;
@property(nonatomic, strong) NSData *codeSignatureBlob;

@end

@implementation MSBasicMachOParser

- (instancetype)initWithBundle:(NSBundle *)bundle {
  if (!bundle || !bundle.executableURL) {
    MSLogError([MSUpdates logTag], @"Given bundle is null or doesn't contain a valid executable URL.");
    return nil;
  }
  if ((self = [super init])) {
    _fileURL = bundle.executableURL;
    _codeSignatureBlob = [[NSData alloc] init];
    _uuid = nil;
    [self parse];
  }
  return self;
}

+ (instancetype)machOParserForMainBundle {
  static MSBasicMachOParser *parser = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    parser = [[self alloc] initWithBundle:MS_APP_MAIN_BUNDLE];
  });
  return parser;
}

- (void)parse {
  NSError *error;
  UInt32 magic;
  NSFileHandle *fh = [NSFileHandle fileHandleForReadingFromURL:self.fileURL error:&error];
  if (error) {
    MSLogError([MSUpdates logTag], @"Cannot get file handle for reading: \n\t%@", error.localizedDescription);
    return;
  }
  if (![self readDataFromFile:fh toBuffer:&magic ofLength:sizeof(magic)]) {
    return;
  }

  // Do the magic.
  [fh seekToFileOffset:0];
  switch (magic) {
  case (UInt32)FAT_MAGIC:
  case (UInt32)FAT_MAGIC_64:
  case (UInt32)FAT_CIGAM:
  case (UInt32)FAT_CIGAM_64:

    /*
     * It's not really the cleanest design, but for simplicity we
     * assume this routine will have seeked the fh to the
     * appropriate embedded Mach-O binary for the current arch.
     */
    [self handleFatHeaders:fh];
    break;
  case (UInt32)MH_MAGIC:
  case (UInt32)MH_MAGIC_64:
    break;
  case (UInt32)MH_CIGAM:
  case (UInt32)MH_CIGAM_64:
    MSLogError([MSUpdates logTag], kMSBigEndianErrorDesc);
    return;
  default:
    MSLogError([MSUpdates logTag], kMSNotMachOErrorDesc);
    return;
  }

  const UInt64 base = fh.offsetInFile;
  struct mach_header header;
  if (![self readDataFromFile:fh toBuffer:&header ofLength:sizeof(struct mach_header)]) {
    return;
  }

  // Validate file.
  if (header.magic == MH_CIGAM || header.magic == MH_CIGAM_64) {
    MSLogError([MSUpdates logTag], kMSBigEndianErrorDesc);
    return;
  }
  if (header.magic != MH_MAGIC && header.magic != MH_MAGIC_64) {
    MSLogError([MSUpdates logTag], kMSNotMachOErrorDesc);
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
    switch (lcmd.cmd) {
    case (UInt32)LC_CODE_SIGNATURE: {
      struct linkedit_data_command cscmd;
      if (![self readDataFromFile:fh toBuffer:&cscmd ofLength:sizeof(cscmd)]) {
        return;
      }
      const UInt64 cmdOffset = fh.offsetInFile;
      [fh seekToFileOffset:(base + (UInt64)cscmd.dataoff)];
      NSData *blob = [fh readDataOfLength:(int)cscmd.datasize];
      if (blob.length != (NSUInteger)(cscmd.datasize)) {
        MSLogError([MSUpdates logTag], kMSCantReadErrorDescFormat, fh);
        return;
      }
      self.codeSignatureBlob = blob;
      [fh seekToFileOffset:cmdOffset];
      break;
    }
    case (UInt32)LC_UUID: {
      struct uuid_command uuidcmd;
      if (![self readDataFromFile:fh toBuffer:&uuidcmd ofLength:sizeof(uuidcmd)]) {
        return;
      }
      self.uuid = [[NSUUID alloc] initWithUUIDBytes:uuidcmd.uuid];
      break;
    }
    default:
      [fh seekToFileOffset:(fh.offsetInFile + (UInt16)lcmd.cmdsize)];
      break;
    }
  }
}

- (BOOL)readDataFromFile:(NSFileHandle *)fh toBuffer:(void *)buffer ofLength:(NSUInteger)size {
  NSData *data = [fh readDataOfLength:size];
  if (data.length != size) {
    MSLogError([MSUpdates logTag], kMSCantReadErrorDescFormat, fh);
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
  UInt32 magic = CFSwapInt32HostToBig(header.magic);
  if (magic == FAT_CIGAM || magic == FAT_CIGAM_64) {
    MSLogError([MSUpdates logTag], kMSBigEndianErrorDesc);
    return;
  }
  if (magic != FAT_MAGIC && magic != FAT_MAGIC_64) {
    MSLogError([MSUpdates logTag], kMSNotMachOErrorDesc);
    return;
  }
  const BOOL is64 = (magic == FAT_MAGIC_64);
  const UInt32 nArch = CFSwapInt32HostToBig(header.nfat_arch);
  const NXArchInfo *myArch;
  const NXArchInfo *thisArch = NXGetLocalArchInfo();
  if (!thisArch) {
    MSLogError([MSUpdates logTag], @"Cannot get local architecture info.");
    return;
  }

  /*
   * HACK: x86_64h (64-bit Simulator on modern Mac hardware)
   * causes NXFindBestFatArch_64() to incorrectly select i386 instead of
   * the desired x86_64. This is an Apple bug.
   */
  if (strcmp(thisArch->name, "x86_64h") == 0) {
    myArch = NXGetArchInfoFromName("x86_64");
  } else {
    myArch = thisArch;
  }

  // These loops might be inefficient that way but it's easier than dealing with pointers.
  struct fat_arch_64 *archs = (struct fat_arch_64 *)malloc(sizeof(struct fat_arch_64) * nArch);
  if (is64) {
    for (UInt32 i = 0; i < nArch; i++) {
      struct fat_arch_64 arch;
      if (![self readDataFromFile:fh toBuffer:&arch ofLength:sizeof(arch)]) {
        free(archs);
        return;
      }
      arch.cputype = (cpu_type_t)CFSwapInt32HostToBig(arch.cputype);
      arch.cpusubtype = (cpu_subtype_t)CFSwapInt32HostToBig(arch.cpusubtype);
      arch.offset = CFSwapInt64HostToBig(arch.offset);
      arch.size = CFSwapInt64HostToBig(arch.size);
      arch.align = CFSwapInt32HostToBig(arch.align);
      *(archs + i) = arch;
    }
  } else {
    for (UInt32 i = 0; i < nArch; i++) {
      struct fat_arch arch;
      if (![self readDataFromFile:fh toBuffer:&arch ofLength:sizeof(arch)]) {
        free(archs);
        return;
      }
      struct fat_arch_64 arch64;
      arch64.cputype = (cpu_type_t)CFSwapInt32HostToBig(arch.cputype);
      arch64.cpusubtype = (cpu_subtype_t)CFSwapInt32HostToBig(arch.cpusubtype);
      arch64.offset = CFSwapInt64HostToBig(CFSwapInt32HostToBig(arch.offset));
      arch64.size = CFSwapInt64HostToBig(CFSwapInt32HostToBig(arch.size));
      arch64.align = CFSwapInt32HostToBig(arch.align);
      *(archs + i) = arch64;
    }
  }
  const struct fat_arch_64 *p =
      NXFindBestFatArch_64(myArch->cputype, myArch->cpusubtype, &archs[0], (UInt32)sizeof(archs));
  if (!p) {
    MSLogError([MSUpdates logTag], @"Cannot find the best match fat architecture.");
  } else {
    [fh seekToFileOffset:p->offset];
  }
  free(archs);
}

@end
