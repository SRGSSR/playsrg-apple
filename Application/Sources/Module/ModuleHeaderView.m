//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "ModuleHeaderView.h"

#import "AnalyticsConstants.h"
#import "NSBundle+PlaySRG.h"
#import "UIColor+PlaySRG.h"

@import SRGAnalytics;
@import SRGAppearance;

@interface ModuleHeaderView ()

@property (nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (nonatomic, weak) IBOutlet UILabel *subtitleLabel;

@end

@implementation ModuleHeaderView

#pragma mark Class methods

+ (CGFloat)heightForModule:(SRGModule *)module withSize:(CGSize)size
{
    // No header displayed on compact vertical layouts
    UITraitCollection *traitCollection = UIApplication.sharedApplication.keyWindow.traitCollection;
    if (traitCollection.verticalSizeClass == UIUserInterfaceSizeClassCompact) {
        return 0.f;
    }
    
    ModuleHeaderView *headerView = [NSBundle.mainBundle loadNibNamed:NSStringFromClass(self) owner:nil options:nil].firstObject;
    headerView.module = module;
    
    // Force autolayout with correct frame width so that the layout is accurate
    headerView.frame = CGRectMake(CGRectGetMinX(headerView.frame), CGRectGetMinY(headerView.frame), size.width, CGRectGetHeight(headerView.frame));
    [headerView setNeedsLayout];
    [headerView layoutIfNeeded];
    
    // Return the minimum size which satisfies the constraints. Put a strong requirement on width and properly let the height
    // adjust
    // For an explanation, see http://titus.io/2015/01/13/a-better-way-to-autosize-in-ios-8.html
    CGSize fittingSize = UILayoutFittingCompressedSize;
    fittingSize.width = size.width;
    return [headerView systemLayoutSizeFittingSize:fittingSize
                     withHorizontalFittingPriority:UILayoutPriorityRequired
                           verticalFittingPriority:UILayoutPriorityFittingSizeLevel].height;
}

#pragma mark Overrides

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.backgroundColor = UIColor.clearColor;
}

- (void)layoutSubviews
{
    // To get a correct intrinsic size for a multiline label, we need to set its preferred max layout width
    // (also when using -systemLayoutSizeFittingSize:withHorizontalFittingPriority:verticalFittingPriority:)
    self.subtitleLabel.preferredMaxLayoutWidth = CGRectGetWidth(self.subtitleLabel.frame);
}

#pragma mark Getters and setters

- (void)setModule:(SRGModule *)module
{
    _module = module;
    
    self.titleLabel.font = [UIFont srg_mediumFontWithTextStyle:SRGAppearanceFontTextStyleTitle];
    self.titleLabel.text = module.title;
    
    self.subtitleLabel.font = [UIFont srg_regularFontWithTextStyle:SRGAppearanceFontTextStyleBody];
    self.subtitleLabel.text = module.lead;
}

@end
