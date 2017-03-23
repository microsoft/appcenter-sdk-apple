#import "MSCrashes.h"
#import <CrashReporter/CrashReporter.h>

#import <string>
#import <array>
#import <unordered_map>

@class MSMPLCrashReporter;

/**
 * Data structure for logs that need to be flushed at crash time to make sure no log is lost at crash time.
 *
 * @property bufferPath The path where the buffered log should be persisted.
 * @property buffer The actual buffered data. It comes in the form of a std::string but actually contains an NSData
 * object which is a serialized log.
 * @property internalId An internal id that helps keep track of logs.
 * @property timestamp A timestamp that is used to determine which bufferedLog to delete in case the buffer is full.
 */
struct MSCrashesBufferedLog {
  std::string bufferPath;
  std::string buffer;
  std::string internalId;
  std::string timestamp;

  MSCrashesBufferedLog() = default;

  MSCrashesBufferedLog(NSString *path, NSData *data)
    : bufferPath(path.UTF8String), buffer(&reinterpret_cast<const char *>(data.bytes)[0], &reinterpret_cast<const char *>(data.bytes)[data.length]) {}
};

/**
 * Constant for size of our log buffer.
 */
const int ms_crashes_log_buffer_size = 20;

/**
 * The log buffer object where we keep out BUFFERED_LOGs which will be written to disk in case of a crash.
 * It's a map that maps 1 array of MSCrashesBufferedLog to a MSPriority.
 */
extern std::unordered_map<MSPriority, std::array<MSCrashesBufferedLog, ms_crashes_log_buffer_size>> msCrashesLogBuffer;

@interface MSCrashes () <MSChannelDelegate, MSLogManagerDelegate>

/**
 * Prototype of a callback function used to execute additional user code. Called
 * upon completion of crash handling, after the crash report has been written to disk.
 *
 * @param context The API client's supplied context value.
 *
 * @see `MSCrashesCallbacks`
 * @see `[MSCrashes setCrashCallbacks:]`
 */
typedef void (*MSCrashesPostCrashSignalCallback)(void *context);

/**
 * This structure contains callbacks supported by `MSCrashes` to allow the host
 * application to perform additional tasks prior to program termination after a crash has occurred.
 *
 * @see `MSCrashesPostCrashSignalCallback`
 * @see `[MSCrashes setCrashCallbacks:]`
 */
typedef struct MSCrashesCallbacks {

  /** An arbitrary user-supplied context value. This value may be NULL. */
  void *context;

  /**
   * The callback used to report caught signal information.
   */
  MSCrashesPostCrashSignalCallback handleSignal;
} MSCrashesCallbacks;

@property(nonatomic, assign, getter=isMachExceptionHandlerEnabled) BOOL enableMachExceptionHandler;

/**
 * A list containing all crash files that currently stored on disk for this app.
 */
@property(nonatomic, copy) NSMutableArray *crashFiles;

/**
 * The directory where all crash reports are stored.
 */
@property(nonatomic, copy) NSURL *crashesDir;

/**
 * The directory where all buffered logs are stored.
 */
@property(nonatomic, copy) NSURL *logBufferDir;

/**
 * A file used to indicate that a crash which occurred in the last session is
 * currently written to disk.
 */
@property(nonatomic, copy) NSURL *analyzerInProgressFile;

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
 * A `NSFileManager` instance used for reading and writing crash reports.
 */
@property(nonatomic) NSFileManager *fileManager;

/**
 * The exception handler used by the crashes service.
 */
@property(nonatomic) NSUncaughtExceptionHandler *exceptionHandler;

/**
 * A flag that indicates that crashes are currently sent to the backend.
 */
@property(nonatomic) BOOL sendingInProgress;

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
 * Determine whether delegate has an attachment callback for error report or not.
 *
 * @return YES if delegate has an attachment callback, otherwise NO.
 */
- (BOOL)delegateImplementsAttachmentCallback;

/**
 * Save the managed exception information in the event of a crash from a wrapper sdk.
 */
+ (void)wrapperCrashCallback;

/**
 * Creates log buffer to buffer logs which will be saved in an async-safe manner
 * at crash time. The buffer makes sure we don't loose any logs at crashtime.
 * This method creates 20 files that will be used to buffer 20 logs.
 * The files will only be created once and not recreated from scratch every time MSCrashes
 * is initialized.
 */
- (void)setupLogBuffer;

/**
 * Returns a file that can be used to save a buffered event log at crash time and triggers creation of a file if
 * it doesn't exist.
 *
 * @param name The name for the file.
 * @param priority The priority for the new file.
 *
 * @return the path for the created or existing file, returns nil if the creation failed.
 *
 * @discussion This will either return the path to the buffer file if one already exists or trigger creation of a file
 * asynchronously by using the @see createBufferFileAtPath: method.
 */
- (NSURL *)fileURLWithName:(NSString *)name forPriority:(MSPriority)priority;

/**
 * A method to create a file at a certain path. This method uses a synchronized block and should be called
 * asynchronously.
 *
 * @param fileURL the file url.
 */
- (void)createBufferFileAtURL:(NSURL *)fileURL;

/**
 * Does not delete the files for our log buffer but "resets" them to be empty. For this,
 * it actually overwrites the old file with an empty copy of the original one.
 * The reason why we are not truly deleting the files is that they need to exist at crash time.
 */
- (void)emptyLogBufferFiles;

/**
 * Return the url for buffered logs for a priority.
 *
 * @param priority A priority for logs.
 * @return The url to the directory for a priority.
 */
- (NSURL *)bufferDirectoryForPriority:(MSPriority)priority;

@end
