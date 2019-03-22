//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <UIKit/UIKit.h>

#import <SRGDataProvider/SRGDataProvider.h>
#import <SRGLetterbox/SRGLetterbox.h>

NS_ASSUME_NONNULL_BEGIN

@interface LiveAccessView : UIView

@property (class, nonatomic, readonly) CGFloat height;

@property (nonatomic, weak, nullable) SRGLetterboxController *letterboxController;

@property (nonatomic, readonly) SRGMediaType mediaType;
@property (nonatomic, readonly) NSArray<SRGMedia *> *medias;

- (void)refreshWithMediaType:(SRGMediaType)mediaType withCompletionBlock:(void (^)(NSError * _Nullable error))completionBlock;

- (void)updateLiveAccessButtonsSelection;

@end

NS_ASSUME_NONNULL_END
