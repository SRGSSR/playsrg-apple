//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "MostSearchedShowCollectionViewCell.h"

#import "UIColor+PlaySRG.h"

#import <SRGAppearance/SRGAppearance.h>

@interface MostSearchedShowCollectionViewCell ()

@property (nonatomic, weak) IBOutlet UILabel *titleLabel;

@end

@implementation MostSearchedShowCollectionViewCell

#pragma mark Overrides

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    UIColor *backgroundColor = UIColor.play_blackColor;
    self.backgroundColor = backgroundColor;
    
    self.titleLabel.backgroundColor = backgroundColor;
}

- (void)setHighlighted:(BOOL)highlighted
{
    super.highlighted = highlighted;
    
    self.titleLabel.textColor = highlighted ? UIColor.lightGrayColor : UIColor.whiteColor;
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
    [super traitCollectionDidChange:previousTraitCollection];
    
    [self play_registerForPreview];
}

#pragma mark Getters and setters

- (void)setShow:(SRGShow *)show
{
    _show = show;
    
    self.titleLabel.font = [UIFont srg_regularFontWithTextStyle:UIFontTextStyleBody];
    self.titleLabel.text = show.title;
}

#pragma mark Previewing protocol

- (id)previewObject
{
    return self.show;
}

- (NSValue *)previewAnchorRect
{
    return [NSValue valueWithCGRect:CGRectMake(0.f, 0.f, 30.f, CGRectGetHeight(self.frame))];
}

@end
