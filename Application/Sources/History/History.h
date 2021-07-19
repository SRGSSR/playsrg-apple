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
 *
 *  @discussion Can be called on any thread.
 */
OBJC_EXPORT float HistoryPlaybackProgress(NSTimeInterval playbackPosition, double durationInSeconds);

/**
 *  Current playback progress value for a media metadata.
 *
 *  @discussion The non-async variant must be called on the main thread. The async variant block can be called from
 *              any thread.
 */
OBJC_EXPORT float HistoryPlaybackProgressForMediaMetadata(id<SRGMediaMetadata> _Nullable mediaMetadata);
OBJC_EXPORT NSString *HistoryPlaybackProgressForMediaMetadataAsync(id<SRGMediaMetadata> _Nullable mediaMetadata, void (^update)(float progress));

/**
 *  Return a recommended resume playback position for a media metadata.
 *
 *  @discussion The non-async variant must be called on the main thread. The async variant block can be called from
 *              any thread.
 */
OBJC_EXPORT SRGPosition * _Nullable HistoryResumePlaybackPositionForMediaMetadata(id<SRGMediaMetadata> _Nullable mediaMetadata);
OBJC_EXPORT NSString *HistoryResumePlaybackPositionForMediaMetadataAsync(id<SRGMediaMetadata> _Nullable mediaMetadata, void (^completion)(SRGPosition * _Nullable position));

/**
 *  Return `YES` if playback can be resumed (or started, a special case of resuming) for some media metadata and position
 *
 *  *  @discussion Can be called on any thread.
 */
OBJC_EXPORT BOOL HistoryCanResumePlaybackForMediaMetadataAndPosition(NSTimeInterval playbackPosition, id<SRGMediaMetadata> _Nullable mediaMetadata);

/**
 *  Return `YES` if playback can be resumed (or started, a special case of resuming) for some media metadata.
 *
 *  @discussion The non-async variant must be called on the main thread. The async variant block can be called from
 *              any thread.
 */
OBJC_EXPORT BOOL HistoryCanResumePlaybackForMediaMetadata(id<SRGMediaMetadata> _Nullable mediaMetadata);
OBJC_EXPORT NSString *HistoryCanResumePlaybackForMediaMetadataAsync(id<SRGMediaMetadata> _Nullable mediaMetadata, void (^completion)(BOOL canResume));

/**
 *  Remove a list of media metadata from the history.
 *
 *  @discussion Must be called from the main thread. The completion block is called on the main thread.
 */
OBJC_EXPORT void HistoryRemoveMediaMetadataList(NSArray<id<SRGMediaMetadata>> *mediaMetadataList, void (^completion)(NSError * _Nullable error));

/**
 *  Cancel a progress async request.
 */
OBJC_EXPORT void HistoryPlaybackProgressAsyncCancel(NSString * _Nullable handle);

NS_ASSUME_NONNULL_END
