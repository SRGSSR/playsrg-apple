//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "Playlist.h"

NS_ASSUME_NONNULL_BEGIN

@protocol PlaylistDataSource <NSObject>

@property (nonatomic, readonly, nullable) Playlist *play_playlist;

@end

NS_ASSUME_NONNULL_END
