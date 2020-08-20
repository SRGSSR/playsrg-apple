//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "HomeTopicCollectionViewCell.h"

#import "Layout.h"
#import "NSBundle+PlaySRG.h"
#import "UIColor+PlaySRG.h"
#import "UIImageView+PlaySRG.h"

@import SRGAppearance;

@interface HomeTopicCollectionViewCell ()

@property (nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (nonatomic, weak) IBOutlet UIImageView *imageView;
@property (nonatomic, weak) IBOutlet UIView *overlayView;

@end

@implementation HomeTopicCollectionViewCell

#pragma mark Overrides

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.backgroundColor = UIColor.play_cardGrayBackgroundColor;
    
    self.layer.cornerRadius = LayoutStandardViewCornerRadius;
    self.layer.masksToBounds = YES;
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    
    [self.imageView play_resetImage];
}

#pragma mark Getters and setters

- (void)setTopic:(SRGTopic *)topic
{
    _topic = topic;
    
    self.titleLabel.font = [UIFont srg_mediumFontWithTextStyle:SRGAppearanceFontTextStyleBody];
    self.titleLabel.text = topic.title;
    
    self.overlayView.hidden = (topic == nil);
    
    [self.imageView play_requestImageForObject:topic withScale:ImageScaleSmall type:SRGImageTypeDefault placeholder:ImagePlaceholderNone];
}

#pragma mark Accessibility

- (BOOL)isAccessibilityElement
{
    return YES;
}

- (NSString *)accessibilityLabel
{
    return self.topic.title;
}

- (NSString *)accessibilityHint
{
    return PlaySRGAccessibilityLocalizedString(@"Opens topic details.", @"Show cell hint");
}

@end
