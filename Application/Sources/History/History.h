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
 *  Return `YES` iff the history contains an entry for the specified media.
 */
OBJC_EXPORT BOOL HistoryContainsMedia(SRGMedia *media);

/**
 *  Return the playback progress corresponding to the specified playback position and media duration. This takes
 *  into account end tolerance settings which might be applied.
 *
 *  @discussion Can be called on any thread.
 */
OBJC_EXPORT float HistoryPlaybackProgress(NSTimeInterval playbackPosition, double durationInSeconds);

/**
 *  Current playback progress value for a media.
 *
 *  @discussion The non-async variant must be called on the main thread. The async variant block can be called from
 *              any thread.
 */
OBJC_EXPORT float HistoryPlaybackProgressForMedia(SRGMedia * _Nullable media);
OBJC_EXPORT NSString *HistoryPlaybackProgressForMediaAsync(SRGMedia * _Nullable media, void (^update)(float progress));

/**
 *  Return a recommended resume playback position for a media.
 *
 *  @discussion The non-async variant must be called on the main thread. The async variant block can be called from
 *              any thread.
 */
OBJC_EXPORT SRGPosition * _Nullable HistoryResumePlaybackPositionForMedia(SRGMedia * _Nullable media);
OBJC_EXPORT NSString *HistoryResumePlaybackPositionForMediaAsync(SRGMedia * _Nullable media, void (^completion)(SRGPosition * _Nullable position));

/**
 *  Return `YES` if playback can be resumed (or started, a special case of resuming) for some media and position.
 *
 *  @discussion Can be called on any thread.
 */
OBJC_EXPORT BOOL HistoryCanResumePlaybackForMediaAndPosition(NSTimeInterval playbackPosition, SRGMedia * _Nullable media);

/**
 *  Return `YES` if playback can be resumed (or started, a special case of resuming) for some media.
 *
 *  @discussion The non-async variant must be called on the main thread. The async variant block can be called from
 *              any thread.
 */
OBJC_EXPORT BOOL HistoryCanResumePlaybackForMedia(SRGMedia * _Nullable media);
OBJC_EXPORT NSString *HistoryCanResumePlaybackForMediaAsync(SRGMedia * _Nullable media, void (^completion)(BOOL canResume));

/**
 *  Remove a list of medias from the history.
 *
 *  @discussion Must be called from the main thread. The completion block is called on the main thread.
 */
OBJC_EXPORT void HistoryRemoveMedias(NSArray<SRGMedia *> *medias, void (^completion)(NSError * _Nullable error));

/**
 *  Cancel a progress async request.
 */
OBJC_EXPORT void HistoryPlaybackProgressAsyncCancel(NSString * _Nullable handle);

NS_ASSUME_NONNULL_END
