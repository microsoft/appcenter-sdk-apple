#import <array>
#import <string>
#import <unordered_map>

#import "MSChannelDelegate.h"
#import "MSCrashReporter.h"
#import "MSCrashes.h"

@class MSMPLCrashReporter;

/**
 * Data structure for logs that need to be flushed at crash time to make sure no
 * log is lost at crash time.
 *
 * @property bufferPath The path where the buffered log should be persisted.
 * @property buffer The actual buffered data. It comes in the form of a
 * std::string but actually contains an NSData object which is a serialized log.
 * @property internalId An internal id that helps keep track of logs.
 * @property timestamp A timestamp that is used to determine which bufferedLog
 * to delete in case the buffer is full.
 */
struct MSCrashesBufferedLog {
  std::string bufferPath;
  std::string buffer;
  std::string targetTokenPath;
  std::string targetToken;
  std::string internalId;
  NSTimeInterval timestamp;

  MSCrashesBufferedLog() = default;

  MSCrashesBufferedLog(NSString *path, NSData *data)
      : bufferPath(path.UTF8String),
        buffer(&reinterpret_cast<const char *>(data.bytes)[0],
               &reinterpret_cast<const char *>(data.bytes)[data.length]) {}
};

/**
 * Constant for size of our log buffer.
 */
const int ms_crashes_log_buffer_size = 60;

/**
 * The log buffer object where we keep out BUFFERED_LOGs which will be written
 * to disk in case of a crash.
 */
extern std::array<MSCrashesBufferedLog, ms_crashes_log_buffer_size>
    msCrashesLogBuffer;

/**
 * Save the log buffer to files.
 */
extern void ms_save_log_buffer();

@interface MSCrashes () <MSChannelDelegate>

/**
 * Prototype of a callback function used to execute additional user code. Called
 * upon completion of crash handling, after the crash report has been written to
 * disk.
 *
 * @param context The API client's supplied context value.
 *
 * @see `MSCrashesCallbacks`
 * @see `[MSCrashes setCrashCallbacks:]`
 */
typedef void (*MSCrashesPostCrashSignalCallback)(void *context);

/**
 * This structure contains callbacks supported by `MSCrashes` to allow the host
 * application to perform additional tasks prior to program termination after a
 * crash has occurred.
 *
 * @see `MSCrashesPostCrashSignalCallback`
 * @see `[MSCrashes setCrashCallbacks:]`
 */
typedef struct MSCrashesCallbacks {

  /**
   * An arbitrary user-supplied context value. This value may be NULL.
   */
  void *context;

  /**
   * The callback used to report caught signal information.
   */
  MSCrashesPostCrashSignalCallback handleSignal;
} MSCrashesCallbacks;

@property(nonatomic, assign, getter=isMachExceptionHandlerEnabled)
    BOOL enableMachExceptionHandler;

/**
 * A list containing all crash files that currently stored on disk for this app.
 */
@property(nonatomic, copy) NSMutableArray *crashFiles;

/**
 * The path component directory where all crash reports are stored.
 */
@property(nonatomic, copy) NSString *crashesPathComponent;

/**
 * The directory where all buffered logs are stored.
 */
@property(nonatomic, copy) NSString *logBufferPathComponent;

/**
 * A path component that's used to indicate that a crash which occurred in the
 * last session is currently written to disk.
 */
@property(nonatomic, copy) NSString *analyzerInProgressFilePathComponent;

/**
 * The object implements the protocol defined in `MSCrashesDelegate`.
 * @see MSCrashesDelegate
 */
@property(nonatomic, weak) id<MSCrashesDelegate> delegate;

/**
 * The `PLCrashReporter` instance used for crash detection.
 */
@property(nonatomic) MSPLCrashReporter *plCrashReporter;

/**
 * The exception handler used by the crashes service.
 */
@property(nonatomic) NSUncaughtExceptionHandler *exceptionHandler;

/**
 * Temporary storage for crashes logs to handle user confirmation and callbacks.
 */
@property NSMutableArray *unprocessedLogs;
@property NSMutableArray *unprocessedReports;
@property NSMutableArray *unprocessedFilePaths;

/**
 * Custom user confirmation handler.
 */
@property MSUserConfirmationHandler userConfirmationHandler;

/**
 * Delete all data in crashes directory.
 */
- (void)deleteAllFromCrashesDirectory;

/**
 * Determine whether the error report should be processed or not.
 *
 * @param errorReport An error report.
 * @return YES if it should process, otherwise NO.
 */
- (BOOL)shouldProcessErrorReport:(MSErrorReport *)errorReport;

/**
 * Determine whether delegate has an attachment callback for error report or
 * not.
 *
 * @return YES if delegate has an attachment callback, otherwise NO.
 */
- (BOOL)delegateImplementsAttachmentCallback;

/**
 * Creates log buffer to buffer logs which will be saved in an async-safe manner
 * at crash time. The buffer makes sure we don't lose any logs at crash time.
 * This method creates 20 files that will be used to buffer 20 logs.
 * The files will only be created once and not recreated from scratch every time
 * MSCrashes is initialized.
 */
- (void)setupLogBuffer;

/**
 * Sends crashes when given MSUserConfirmationSend.
 */
- (void)notifyWithUserConfirmation:(MSUserConfirmation)userConfirmation;

/**
 * Does not delete the files for our log buffer but "resets" them to be empty.
 * For this, it actually overwrites the old file with an empty copy of the
 * original one. The reason why we are not truly deleting the files is that they
 * need to exist at crash time.
 */
- (void)emptyLogBufferFiles;

/**
 * Method to reset the singleton when running unit tests only. So calling
 * sharedInstance returns a fresh instance.
 */
+ (void)resetSharedInstance;

@end
