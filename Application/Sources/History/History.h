//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "Favorite.h"

#import <SRGDataProvider/SRGDataProvider.h>
#import <SRGMediaPlayer/SRGMediaPlayer.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  Current playback progress value for a media metadata.
 *
 *  @discussion Must be called from the main thread. The asynchronous variant calls the completion block on the main thread.
 */
OBJC_EXPORT float HistoryPlaybackProgressForMediaMetadata(id<SRGMediaMetadata> _Nullable mediaMetadata);
OBJC_EXPORT void HistoryPlaybackProgressForMediaMetadataAsync(id<SRGMediaMetadata> _Nullable mediaMetadata, void (^update)(float progress));

/**
 *  Current playback progress value for a favorite.
 *
 *  @discussion Must be called from the main thread. The asynchronous variant calls the completion block on the main thread.
 */
OBJC_EXPORT float HistoryPlaybackProgressForFavorite(Favorite *favorite);
OBJC_EXPORT void HistoryPlaybackProgressForFavoriteAsync(Favorite *favorite, void (^update)(float progress));

/**
 *  Return a recommended resume playback position for a media.
 *
 *  @discussion Must be called from the main thread
 */
OBJC_EXPORT SRGPosition * _Nullable HistoryResumePlaybackPositionForMedia(SRGMedia *media);

NS_ASSUME_NONNULL_END
