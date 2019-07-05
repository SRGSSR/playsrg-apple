//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "ShowCollectionViewCell.h"

#import "AnalyticsConstants.h"
#import "Banner.h"
#import "NSBundle+PlaySRG.h"
#import "UIColor+PlaySRG.h"
#import "UIImage+PlaySRG.h"
#import "UIImageView+PlaySRG.h"

#import <CoconutKit/CoconutKit.h>
#import <SRGAnalytics/SRGAnalytics.h>
#import <SRGAppearance/SRGAppearance.h>

@interface ShowCollectionViewCell ()

@property (nonatomic) SRGShow *show;

@property (nonatomic, weak) IBOutlet UIView *showView;
@property (nonatomic, weak) IBOutlet UIView *placeholderView;
@property (nonatomic, weak) IBOutlet UIImageView *placeholderImageView;

@property (nonatomic, weak) IBOutlet UIImageView *thumbnailImageView;
@property (nonatomic, weak) IBOutlet UILabel *titleLabel;

@end

@implementation ShowCollectionViewCell

#pragma mark Overrides

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    UIColor *backgroundColor = UIColor.play_blackColor;
    self.backgroundColor = backgroundColor;
    
    self.titleLabel.backgroundColor = backgroundColor;
    
    self.showView.hidden = YES;
    self.placeholderView.hidden = NO;
    
    // Accommodate all kinds of usages (medium or small)
    self.placeholderImageView.image = [UIImage play_vectorImageAtPath:FilePathForImagePlaceholder(ImagePlaceholderMediaList)
                                                            withScale:ImageScaleMedium];
    
    self.thumbnailImageView.backgroundColor = UIColor.play_grayThumbnailImageViewBackgroundColor;
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    
    self.showView.hidden = YES;
    self.placeholderView.hidden = NO;
    
    [self.thumbnailImageView play_resetImage];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
    [super traitCollectionDidChange:previousTraitCollection];
    
    [self.nearestViewController registerForPreviewingWithDelegate:self.nearestViewController sourceView:self];
}

#pragma mark Accessibility

- (BOOL)isAccessibilityElement
{
    return YES;
}

- (NSString *)accessibilityLabel
{
    return self.show.title;
}

- (NSString *)accessibilityHint
{
    return PlaySRGAccessibilityLocalizedString(@"Opens show details.", @"Show cell hint");
}

#pragma mark Getters and setters

- (void)setShow:(SRGShow *)show featured:(BOOL)featured
{
    self.show = show;
    
    if (! show) {
        self.showView.hidden = YES;
        self.placeholderView.hidden = NO;
        return;
    }
    
    self.showView.hidden = NO;
    self.placeholderView.hidden = YES;
    
    self.titleLabel.font = [UIFont srg_mediumFontWithTextStyle:SRGAppearanceFontTextStyleBody];
    self.titleLabel.text = show.title;
    
    ImageScale imageScale = featured ? ImageScaleMedium : ImageScaleSmall;
    [self.thumbnailImageView play_requestImageForObject:show withScale:imageScale type:SRGImageTypeDefault placeholder:ImagePlaceholderMediaList];
}

#pragma mark Previewing protocol

- (id)previewObject
{
    return self.show;
}

@end
