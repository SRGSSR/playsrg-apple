//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

@import SRGDataProvider;

NS_ASSUME_NONNULL_BEGIN

@interface ShowHeaderView : UICollectionReusableView

// Get the height of view with a given show and a witdh, depending of the screen size to adapt
// 16:9 aspect ratio or a smaller one for the show image, on an iPad in landscape
+ (CGFloat)heightForShow:(SRGShow *)show withSize:(CGSize)size;

@property (nonatomic, nullable) SRGShow *show;

- (void)updateAspectRatioWithSize:(CGSize)size;

@end

NS_ASSUME_NONNULL_END
