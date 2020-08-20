//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

@import SRGLetterbox;

NS_ASSUME_NONNULL_BEGIN

@interface Playlist : NSObject <SRGLetterboxControllerPlaylistDataSource>

- (instancetype)initWithURN:(NSString *)URN;

@property (nonatomic, nullable, readonly) NSString *recommendationUid;

@end

NS_ASSUME_NONNULL_END
