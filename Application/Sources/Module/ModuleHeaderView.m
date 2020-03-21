//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "ModuleHeaderView.h"

#import "AnalyticsConstants.h"
#import "NSBundle+PlaySRG.h"
#import "UIColor+PlaySRG.h"
#import "UIImage+PlaySRG.h"
#import "UIImageView+PlaySRG.h"

#import <SRGAnalytics/SRGAnalytics.h>
#import <SRGAppearance/SRGAppearance.h>

// Choose the good aspect ratio for the logo image view, depending of the screen size
static const UILayoutPriority LogoImageViewAspectRatioConstraintNormalPriority = 900;
static const UILayoutPriority LogoImageViewAspectRatioConstraintLowPriority = 700;

@interface ModuleHeaderView ()

@property (nonatomic, weak) IBOutlet UIImageView *logoImageView;
@property (nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (nonatomic, weak) IBOutlet UILabel *subtitleLabel;

@property (nonatomic) IBOutlet NSLayoutConstraint *logoImageViewRatio16_9Constraint; // Need to retain it, because active state removes it
@property (nonatomic) IBOutlet NSLayoutConstraint *logoImageViewRatioBigLandscapeScreenConstraint; // Need to retain it, because active state removes it

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
    
    [headerView updateAspectRatioWithSize:size];
    
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
    
    UIColor *backgroundColor = UIColor.play_blackColor;
    self.backgroundColor = backgroundColor;
    
    self.titleLabel.backgroundColor = backgroundColor;
    self.subtitleLabel.backgroundColor = backgroundColor;
    
    // Accommodate all kinds of usages
    self.logoImageView.image = [UIImage play_vectorImageAtPath:FilePathForImagePlaceholder(ImagePlaceholderMediaList)
                                                     withScale:ImageScaleLarge];
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
    self.subtitleLabel.text = module.lead ?: module.summary;
    
    [self.logoImageView play_requestImageForObject:module withScale:ImageScaleLarge type:SRGImageTypeDefault placeholder:ImagePlaceholderMediaList];
}

#pragma mark UI

- (void)updateAspectRatioWithSize:(CGSize)size
{
    // Use the big landscape screen aspect ratio for player view in landscape orientation on iPad, 16:9 ratio otherwise.
    BOOL isLandscape = (size.width > size.height);
    UITraitCollection *traitCollection = UIApplication.sharedApplication.keyWindow.traitCollection;
    if (traitCollection.verticalSizeClass == UIUserInterfaceSizeClassRegular
            && traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular
            && isLandscape) {
        self.logoImageViewRatio16_9Constraint.priority = LogoImageViewAspectRatioConstraintLowPriority;
        self.logoImageViewRatioBigLandscapeScreenConstraint.priority = LogoImageViewAspectRatioConstraintNormalPriority;
    }
    else {
        self.logoImageViewRatio16_9Constraint.priority = LogoImageViewAspectRatioConstraintNormalPriority;
        self.logoImageViewRatioBigLandscapeScreenConstraint.priority = LogoImageViewAspectRatioConstraintLowPriority;
    }
}

@end
