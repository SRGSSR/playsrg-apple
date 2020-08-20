//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

@import SRGAnalytics;
@import SRGDataProvider;
@import SRGLetterbox;

NS_ASSUME_NONNULL_BEGIN

@interface MediaPreviewViewController : UIViewController <SRGAnalyticsViewTracking, SRGLetterboxViewDelegate>

- (instancetype)initWithMedia:(SRGMedia *)media;

@property (nonatomic, readonly) SRGMedia *media;

@property (nonatomic, readonly, nullable) IBOutlet SRGLetterboxController *letterboxController;

@end

@interface MediaPreviewViewController (Unavailable)

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
