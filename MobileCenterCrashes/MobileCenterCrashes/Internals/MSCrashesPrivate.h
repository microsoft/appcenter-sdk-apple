/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "MSCrashes.h"
#import <CrashReporter/CrashReporter.h>

@class MSMPLCrashReporter;

@interface MSCrashes ()

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

/**
 * A list containing all crash files that currently stored on disk for this app.
 */
@property(nonatomic, copy) NSMutableArray *crashFiles;

/**
 * The directory where all crash reports are stored.
 */
@property(nonatomic, copy) NSString *crashesDir;

/**
 * A file used to indicate that a crash which occurred in the last session is
 * currently written to disk.
 */
@property(nonatomic, copy) NSString *analyzerInProgressFile;

/**
 * A file used as a buffer to write logs to disk ar crash time.
 */
@property(nonatomic, copy) NSString *crashBufferFile;

/**
 * The object implements the protocol defined in `MSCrashesDelegate`.
 * @see MSCrashesDelegate
 */
@property(nonatomic, weak) id <MSCrashesDelegate> delegate;

/**
 * The `PLCrashReporter` instance used for crash detection.
 */
@property(nonatomic, strong) MSPLCrashReporter *plCrashReporter;

/**
 * A `NSFileManager` instance used for reading and writing crash reports.
 */
@property(nonatomic, strong) NSFileManager *fileManager;

/**
 * The exception handler used by the crashes service.
 */
@property(nonatomic) NSUncaughtExceptionHandler *exceptionHandler;

/**
 * A flag that indicates that crashes are currently sent to the backend.
 */
@property(nonatomic) BOOL sendingInProgress;

/**
 * Indicates if the app crashed in the previous session
 *
 * Use this on startup, to check if the app starts the first time after it
 crashed
 * previously. You can use this also to disable specific events, like asking
 * the user to rate your app.

 * @warning This property only has a correct value, once the sdk has been
 properly initialized!

 * @see lastSessionCrashReport
 */
@property(atomic, readonly) BOOL didCrashInLastSession;

/**
 * Detail information about the last crash.
 */
@property(atomic, readonly, getter=getLastSessionCrashReport) MSErrorReport *lastSessionCrashReport;

/**
 * Temporary storage for crashes logs to handle user confirmation and callbacks.
 */
@property(atomic) NSMutableArray *unprocessedLogs;
@property(atomic) NSMutableArray *unprocessedReports;
@property(atomic) NSMutableArray *unprocessedFilePaths;

/**
 * Custom user confirmation handler.
 */
@property(atomic) MSUserConfirmationHandler userConfirmationHandler;

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
 * Save the managed exception information in the event of a crash
 from a wrapper sdk.
 */
+ (void)wrapperCrashCallback;

@end
