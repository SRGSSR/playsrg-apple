//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "Download.h"

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  Notification sent when a favorite state changes (added or removed).
 *  Use the `FavoriteStateKey` to retrieve new state from the notification `userInfo` dictionary
 */
OBJC_EXPORT NSString * const DownloadSessionStateDidChangeNotification;                            // Notification name
OBJC_EXPORT NSString * const DownloadSessionStateKey;                                              // Key to access the current download session state

/**
 *  Download session state
 */
typedef NS_ENUM(NSInteger, DownloadSessionState) {
    /**
     *  Idle state
     */
    DownloadSessionStateIdle,
    /**
     *  Downloading state
     */
    DownloadSessionStateDownloading,
    /**
     *  Downloading Suspended state
     */
    DownloadSessionStateDownloadingSuspended
};

/**
 *  The download session is responsible for managing download processes
 */
@interface DownloadSession : NSObject <NSURLSessionDownloadDelegate>

@property (class, nonatomic, readonly) DownloadSession *sharedDownloadSession;

@property (nonatomic, readonly) DownloadSessionState state;

- (BOOL)addDownload:(Download *)download;
- (void)removeDownload:(Download *)download;
- (BOOL)hasTasksForDownload:(Download *)download;
- (BOOL)isDownloadingDownload:(Download *)download;

- (nullable NSProgress *)currentlyKnownProgressForDownload:(Download *)download;

@end

NS_ASSUME_NONNULL_END
