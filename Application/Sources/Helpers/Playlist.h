//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

@import SRGLetterbox;

NS_ASSUME_NONNULL_BEGIN

@interface Playlist : NSObject <SRGLetterboxControllerPlaybackTransitionDelegate, SRGLetterboxControllerPlaylistDataSource>

- (instancetype)initWithURN:(NSString *)URN;

@property (nonatomic, nullable, readonly) NSString *recommendationUid;

@end

/**
 *  Return a playlist for the specified URN, automatically retained.
 */
OBJC_EXPORT Playlist *PlaylistForURN(NSString *URN);

NS_ASSUME_NONNULL_END
