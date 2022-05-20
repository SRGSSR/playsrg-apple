//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

@import Foundation;
@import SRGDataProviderModel;

NS_ASSUME_NONNULL_BEGIN

/**
 *  Notification sent when a download state changes (added or removed).
 *  Use the `DownloadStateKey` to retrieve new state from the notification `userInfo` dictionary
 */
OBJC_EXPORT NSString * const DownloadStateDidChangeNotification;                            // Notification name
OBJC_EXPORT NSString * const DownloadStateKey;                                              // Key to access the current download state as an `NSNumber` wrapping a `DownloadState`

/**
 *  Notification sent when the progress of a download changes
 */
OBJC_EXPORT NSString * const DownloadProgressDidChangeNotification;                         // Notification name
OBJC_EXPORT NSString * const DownloadProgressKey;                                           // Key to access the current download progress as an `NSProgress` object

/**
 *  The default width used to store the backup image file
 */
OBJC_EXPORT CGFloat const DownloadBackupImageWidth;

/**
 *  Download media types
 */
typedef NS_ENUM(NSInteger, DownloadMediaType) {
    /**
     *  Not specified
     */
    DownloadMediaTypeUnknown = 0,
    /**
     *  Video
     */
    DownloadMediaTypeVideo,
    /**
     *  Audio
     */
    DownloadMediaTypeAudio
};

/**
 *  Download state
 */
typedef NS_ENUM(NSInteger, DownloadState) {
    /**
     *  Not specified
     */
    DownloadStateUnknown = 0,
    /**
     *  Media added to the download list
     */
    DownloadStateAdded,
    /**
     *  Media removed from the download list
     */
    DownloadStateRemoved,
    /**
     *  Media can be downloaded (but was never added or removed)
     */
    DownloadStateDownloadable,
    /**
     *  Media is being downloading
     */
    DownloadStateDownloading,
    /**
     *  Media is downloading, but suspended
     */
    DownloadStateDownloadingSuspended,
    /**
     *  Media has been downloaded
     */
    DownloadStateDownloaded
};

/**
 *  A `Download` collects all information associated with a download, and provides the interface to manage them
 */
@interface Download : NSObject <SRGMediaMetadata>

/**
 *  The date at which the download was created
 */
@property (nonatomic, readonly) NSDate *creationDate;

/**
 *  The recommended way to present the media.
 */
@property (nonatomic, readonly) SRGPresentation presentation;

/**
 *  The local media file, if any
 */
@property (nonatomic, readonly, nullable) NSURL *localMediaFileURL;

/**
 *  The local image file, if any
 */
@property (nonatomic, readonly, nullable) NSURL *localImageFileURL;

/**
 *  The current state
 */
@property (nonatomic, readonly) DownloadState state;

/**
 *  Ask for a (possible) state update
 */
- (void)setNeedsStateUpdate;

/**
 *  The associated media information
 */
@property (nonatomic, readonly, nullable) SRGMedia *media;

/**
 *  The size of the downloaded file in bytes (0 if not downloaded)
 */
@property (nonatomic, readonly) long long size;

@end

@interface Download (Management)

/**
 *  Available downloads, sorted by date at which they were added (from the most recent to the oldest)
 */
@property (class, nonatomic, readonly) NSArray<Download *> *downloads;

/**
 *  Return `YES` iff the download media status can be changed or displayed
 */
+ (BOOL)canToggleDownloadForMedia:(SRGMedia *)media;

/**
 *  Add a download to the download list and start downloading it. Returns `nil` if download is not possible
 *
 *  @discussion If a download already exists for the specified media, it is started (if not already) and returned
 *              instead
 */
+ (nullable Download *)addDownloadForMedia:(SRGMedia *)media;

/**
 *  Return an existing download for the specified media
 */
+ (nullable Download *)downloadForMedia:(SRGMedia *)media;

/**
 *  Return an existing download for the specified URN
 *  If you have a media object, prefer to use downloadForMedia:
 */
+ (Download *)downloadForURN:(NSString *)URN;

/**
 *  Remove an existing download (and associated files)
 */
+ (void)removeDownload:(Download *)download;

/**
 *  Remove all downlaods and associated files
 */
+ (void)removeAllDownloads;

/**
 *  Clean the downloaded folder to ununsed downloaded files
 */
+ (void)removeUnusedDownloadedFiles;

/**
 *  The currently known download progress for a download
 */
+ (nullable NSProgress *)currentlyKnownProgressForDownload:(Download *)download;


@end

NS_ASSUME_NONNULL_END
