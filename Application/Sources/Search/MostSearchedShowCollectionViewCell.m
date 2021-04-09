//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "MostSearchedShowCollectionViewCell.h"

@import SRGAppearance;

@interface MostSearchedShowCollectionViewCell ()

@property (nonatomic, weak) IBOutlet UILabel *titleLabel;

@end

@implementation MostSearchedShowCollectionViewCell

#pragma mark Overrides

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.backgroundColor = UIColor.clearColor;
}

- (void)setHighlighted:(BOOL)highlighted
{
    super.highlighted = highlighted;
    
    self.titleLabel.textColor = highlighted ? UIColor.lightGrayColor : UIColor.whiteColor;
}

- (void)didMoveToWindow
{
    [super didMoveToWindow];
    
    [self play_registerForPreview];
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
    
    self.titleLabel.font = [SRGFont fontWithStyle:SRGFontStyleH4];
    self.titleLabel.text = show.title;
}

#pragma mark Previewing protocol

- (id)previewObject
{
    return self.show;
}

@end
