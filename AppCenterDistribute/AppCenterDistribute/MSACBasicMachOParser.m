// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <mach-o/arch.h>
#import <mach-o/fat.h>
#import <mach-o/loader.h>

#import "MSACBasicMachOParser.h"
#import "MSACDistributeInternal.h"
#import "MSACLogger.h"
#import "MSACUtility.h"

static NSString *const kMSACBigEndianErrorDesc = @"Big-endian file not supported.";
static NSString *const kMSACNotMachOErrorDesc = @"File is not a known type of Mach-O file.";
static NSString *const kMSACCantReadErrorDescFormat = @"Cannot read data from file %@";

@interface MSACBasicMachOParser ()

@property(nonatomic) NSURL *fileURL;

@end

@implementation MSACBasicMachOParser

- (instancetype)initWithBundle:(NSBundle *)bundle {
  if (!bundle || !bundle.executableURL) {
    MSACLogError([MSACDistribute logTag], @"Given bundle is null or doesn't contain a valid executable URL.");
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
  static MSACBasicMachOParser *parser = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    parser = [[MSACBasicMachOParser alloc] initWithBundle:MSAC_APP_MAIN_BUNDLE];
  });
  return parser;
}

- (void)parse {
  NSError *error;
  UInt32 magic;
  NSFileHandle *fh = [NSFileHandle fileHandleForReadingFromURL:self.fileURL error:&error];
  if (error) {
    MSACLogError([MSACDistribute logTag], @"Cannot get file handle for reading: \n\t%@", error.localizedDescription);
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
    MSACLogError([MSACDistribute logTag], kMSACBigEndianErrorDesc);
    return;
  default:
    MSACLogError([MSACDistribute logTag], kMSACNotMachOErrorDesc);
    return;
  }

  struct mach_header header;
  if (![self readDataFromFile:fh toBuffer:&header ofLength:sizeof(struct mach_header)]) {
    return;
  }

  // Validate file.
  if (header.magic == MH_CIGAM || header.magic == MH_CIGAM_64) {
    MSACLogError([MSACDistribute logTag], kMSACBigEndianErrorDesc);
    return;
  }
  if (header.magic != MH_MAGIC && header.magic != MH_MAGIC_64) {
    MSACLogError([MSACDistribute logTag], kMSACNotMachOErrorDesc);
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
    MSACLogError([MSACDistribute logTag], kMSACCantReadErrorDescFormat, fh);
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
    MSACLogError([MSACDistribute logTag], kMSACBigEndianErrorDesc);
    return;
  }
  if (magic != FAT_MAGIC) {
    MSACLogError([MSACDistribute logTag], kMSACNotMachOErrorDesc);
    return;
  }
  const UInt32 nArch = CFSwapInt32BigToHost(header.nfat_arch);
  const NXArchInfo *myArch = NXGetLocalArchInfo();
  if (!myArch) {
    MSACLogError([MSACDistribute logTag], @"Cannot get local architecture info.");
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
    MSACLogError([MSACDistribute logTag], @"Cannot find the best match fat architecture.");
  } else {
    [fh seekToFileOffset:p->offset];
  }
  free(archs);
}

@end
