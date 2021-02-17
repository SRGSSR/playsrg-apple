//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

@import SRGDataProviderModel;

NS_ASSUME_NONNULL_BEGIN

@interface ModuleHeaderView : UICollectionReusableView

// Get the height of view with a given show and a witdh, depending of the screen size to adapt
// 16:9 aspect ratio or a smaller one for the show image, on an iPad in landscape
+ (CGFloat)heightForModule:(SRGModule *)module withSize:(CGSize)size;

@property (nonatomic, nullable) SRGModule *module;

@end

NS_ASSUME_NONNULL_END
