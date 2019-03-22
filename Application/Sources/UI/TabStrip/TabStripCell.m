//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "TabStripCell.h"

#import "UIColor+PlaySRG.h"

#import <SRGAppearance/SRGAppearance.h>

@interface TabStripCell ()

@property (nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (nonatomic, weak) IBOutlet UIImageView *imageView;

@end

@implementation TabStripCell

#pragma mark Class methods

+ (CGFloat)widthForItem:(PageItem *)item withHeight:(CGFloat)height
{
    TabStripCell *cell = [[NSBundle bundleForClass:self] loadNibNamed:NSStringFromClass(self) owner:nil options:nil].firstObject;
    cell.item = item;
    
    // Force autolayout
    [cell setNeedsLayout];
    [cell layoutIfNeeded];
    
    // Return the minimum size which satisfies the constraints. Put a strong requirement on height and properly let the width
    // adjust
    // For an explanation, see http://titus.io/2015/01/13/a-better-way-to-autosize-in-ios-8.html
    CGSize fittingSize = UILayoutFittingCompressedSize;
    fittingSize.height = height;
    return [cell systemLayoutSizeFittingSize:fittingSize
               withHorizontalFittingPriority:UILayoutPriorityFittingSizeLevel
                     verticalFittingPriority:UILayoutPriorityRequired].width;
}

#pragma mark Overrides

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.backgroundColor = UIColor.clearColor;
    self.titleLabel.textColor = UIColor.play_grayColor;
    self.imageView.tintColor = UIColor.whiteColor;
}

#pragma mark Accessibility

- (BOOL)isAccessibilityElement
{
    return YES;
}

- (NSString *)accessibilityLabel
{
    return self.item.title;
}

- (UIAccessibilityTraits)accessibilityTraits
{
    // Treat each tab as a section for quick navigation between categories
    return UIAccessibilityTraitHeader;
}

#pragma mark Getters and setters

- (void)setItem:(PageItem *)item
{
    _item = item;
    
    if (item.image) {
        self.imageView.image = item.image;
        self.titleLabel.text = nil;
    }
    else {
        self.imageView.image = nil;
        self.titleLabel.text = item.title.uppercaseString;
        self.titleLabel.font = [UIFont srg_mediumFontWithTextStyle:SRGAppearanceFontTextStyleBody];
    }
}

- (void)setCurrent:(BOOL)current
{
    self.titleLabel.textColor = current ? UIColor.whiteColor : UIColor.play_grayColor;
}

@end
