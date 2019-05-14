//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <SRGDataProvider/SRGDataProvider.h>
#import <SRGMediaPlayer/SRGMediaPlayer.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  Return the playback progress corresponding to the specified playback position and media duration. This takes
 *  into account end tolerance settings which might be applied.
 */
OBJC_EXPORT float HistoryPlaybackProgress(NSTimeInterval playbackPosition, double durationInSeconds);

/**
 *  Current playback progress value for a media metadata.
 *
 *  @discussion Must be called from the main thread. The asynchronous variant calls the completion block on the main thread.
 */
OBJC_EXPORT float HistoryPlaybackProgressForMediaMetadata(id<SRGMediaMetadata> _Nullable mediaMetadata);
OBJC_EXPORT void HistoryPlaybackProgressForMediaMetadataAsync(id<SRGMediaMetadata> _Nullable mediaMetadata, void (^update)(float progress));

/**
 *  Return a recommended resume playback position for a media.
 *
 *  @discussion Must be called from the main thread
 */
OBJC_EXPORT SRGPosition * _Nullable HistoryResumePlaybackPositionForMedia(SRGMedia *media);

NS_ASSUME_NONNULL_END
