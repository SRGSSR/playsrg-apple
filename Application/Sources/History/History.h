//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

@import SRGDataProviderModel;
@import SRGLetterbox;
@import SRGMediaPlayer;

NS_ASSUME_NONNULL_BEGIN

/**
 *  Update playback progress based on the provided controller.
 */
OBJC_EXPORT void HistoryUpdateLetterboxPlaybackProgress(SRGLetterboxController *letterboxController);

/**
 *  Return the playback progress corresponding to the specified playback position and media duration. This takes
 *  into account end tolerance settings which might be applied.
 */
OBJC_EXPORT float HistoryPlaybackProgress(NSTimeInterval playbackPosition, double durationInSeconds);

/**
 *  Current playback progress value for a media metadata.
 *
 *  @discussion Must be called from the main thread. The asynchronous variant calls the completion block on the main thread,
 *              and returns a handle with which the asynchronous request can be cancelled.
 */
OBJC_EXPORT float HistoryPlaybackProgressForMediaMetadata(id<SRGMediaMetadata> _Nullable mediaMetadata);
OBJC_EXPORT NSString *HistoryPlaybackProgressForMediaMetadataAsync(id<SRGMediaMetadata> _Nullable mediaMetadata, void (^update)(float progress));

/**
 *  Cancel a progress async request.
 */
OBJC_EXPORT void HistoryPlaybackProgressAsyncCancel(NSString * _Nullable handle);

/**
 *  Return a recommended resume playback position for a media.
 *
 *  @discussion Must be called from the main thread
 */
OBJC_EXPORT SRGPosition * _Nullable HistoryResumePlaybackPositionForMedia(SRGMedia *media);

/**
 *  Return `YES` if playback can be resumed (or started, a special case of resuming).
 *
 *  @discussion Must be called from the main thread
 */
OBJC_EXPORT BOOL HistoryCanResumePlaybackForMedia(SRGMedia *media);

NS_ASSUME_NONNULL_END
