#import "MSUtility+Environment.h"

#import <mach-o/dyld.h>

/*
 * Workaround for exporting symbols from category object files.
 */
NSString *MSUtilityEnvironmentCategory;

@implementation MSUtility (Environment)

+ (MSEnvironment)currentAppEnvironment {
#if TARGET_OS_SIMULATOR
  return MSEnvironmentOther;
#elif TARGET_OS_OSX
  if (isAppEncrypted()) {
    return MSEnvironmentAppStore;
  }
  return MSEnvironmentOther;
#else

  // MobilePovision profiles are a clear indicator for Ad-Hoc distribution.
  if ([self hasEmbeddedMobileProvision]) {
    return MSEnvironmentOther;
  }

  /**
   * TestFlight is only supported from iOS 8 onwards and as our deployment target is iOS 8, we don't have to do any
   * checks for floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_6_1).
   */
  if ([self isAppStoreReceiptSandbox]) {
    return MSEnvironmentTestFlight;
  }

  return MSEnvironmentAppStore;
#endif
}

+ (BOOL)hasEmbeddedMobileProvision {
  BOOL hasEmbeddedMobileProvision = !![[NSBundle mainBundle] pathForResource:@"embedded" ofType:@"mobileprovision"];
  return hasEmbeddedMobileProvision;
}

+ (BOOL)isAppStoreReceiptSandbox {
#if TARGET_OS_SIMULATOR
  return NO;
#else
  if (![NSBundle.mainBundle respondsToSelector:@selector(appStoreReceiptURL)]) {
    return NO;
  }
  NSURL *appStoreReceiptURL = NSBundle.mainBundle.appStoreReceiptURL;
  NSString *appStoreReceiptLastComponent = appStoreReceiptURL.lastPathComponent;

  BOOL isSandboxReceipt = [appStoreReceiptLastComponent isEqualToString:@"sandboxReceipt"];
  return isSandboxReceipt;
#endif
}

#if TARGET_OS_OSX
static BOOL isAppEncrypted() {
  const struct mach_header *executableHeader = NULL;
  for (uint32_t i = 0; i < _dyld_image_count(); i++) {
    const struct mach_header *header = _dyld_get_image_header(i);
    if (header && header->filetype == MH_EXECUTE) {
      executableHeader = header;
      break;
    }
  }

  if (!executableHeader) {
    return NO;
  }

  BOOL is64bit = (executableHeader->magic == MH_MAGIC_64);
  uintptr_t cursor = (uintptr_t)executableHeader +
  (is64bit ? sizeof(struct mach_header_64) : sizeof(struct mach_header));
  const struct segment_command *segmentCommand = NULL;
  uint32_t i = 0;

  while (i++ < executableHeader->ncmds) {
    segmentCommand = (struct segment_command *)cursor;

    if (!segmentCommand) {
      continue;
    }

    if ((!is64bit && segmentCommand->cmd == LC_ENCRYPTION_INFO) ||
        (is64bit && segmentCommand->cmd == LC_ENCRYPTION_INFO_64)) {
      if (is64bit) {
        const struct encryption_info_command_64 *cryptCmd = (const struct encryption_info_command_64 *)segmentCommand;
        return cryptCmd && cryptCmd->cryptid != 0;
      } else {
        const struct encryption_info_command *cryptCmd = (const struct encryption_info_command *)segmentCommand;
        return cryptCmd && cryptCmd->cryptid != 0;
      }
    }
    cursor += segmentCommand->cmdsize;
  }

  return NO;
}
#endif

@end
