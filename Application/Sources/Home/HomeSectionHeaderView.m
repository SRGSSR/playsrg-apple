//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "HomeSectionHeaderView.h"

#import "ApplicationConfiguration.h"
#import "HomeMediasViewController.h"
#import "HomeTopicViewController.h"
#import "ModuleViewController.h"
#import "NSBundle+PlaySRG.h"
#import "PageViewController.h"

#import <CoconutKit/CoconutKit.h>
#import <SRGAppearance/SRGAppearance.h>

@interface HomeSectionHeaderView ()

@property (nonatomic, weak) IBOutlet UIView *moduleBackgroundView;
@property (nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (nonatomic, weak) IBOutlet UIButton *navigationButton;

@end

@implementation HomeSectionHeaderView

#pragma mark Class overrides

+ (CGFloat)height
{
    static NSDictionary<NSString *, NSNumber *> *s_headerHeights;
    static dispatch_once_t s_onceToken;
    dispatch_once(&s_onceToken, ^{
        s_headerHeights = @{ UIContentSizeCategoryExtraSmall : @25,
                             UIContentSizeCategorySmall : @30,
                             UIContentSizeCategoryMedium : @35,
                             UIContentSizeCategoryLarge : @40,
                             UIContentSizeCategoryExtraLarge : @40,
                             UIContentSizeCategoryExtraExtraLarge : @40,
                             UIContentSizeCategoryExtraExtraExtraLarge : @45,
                             UIContentSizeCategoryAccessibilityMedium : @45,
                             UIContentSizeCategoryAccessibilityLarge : @45,
                             UIContentSizeCategoryAccessibilityExtraLarge : @45,
                             UIContentSizeCategoryAccessibilityExtraExtraLarge : @45,
                             UIContentSizeCategoryAccessibilityExtraExtraExtraLarge : @45 };
    });
    
    NSString *contentSizeCategory = UIApplication.sharedApplication.preferredContentSizeCategory;
    return s_headerHeights[contentSizeCategory].floatValue;
}

#pragma mark Getters and setters

- (void)setHomeSectionInfo:(HomeSectionInfo *)homeSectionInfo
{
    _homeSectionInfo = homeSectionInfo;
    
    UIColor *backgroundColor = UIColor.clearColor;
    UIColor *titleTextColor = UIColor.whiteColor;
    if (homeSectionInfo.module && ! ApplicationConfiguration.sharedApplicationConfiguration.moduleColorsDisabled) {
        backgroundColor = homeSectionInfo.module.backgroundColor;
        titleTextColor = homeSectionInfo.module.linkColor ?: ApplicationConfiguration.sharedApplicationConfiguration.moduleDefaultLinkColor;
    }
    
    self.moduleBackgroundView.backgroundColor = backgroundColor;
    
    self.titleLabel.textColor = titleTextColor;
    self.titleLabel.font = [UIFont srg_mediumFontWithTextStyle:SRGAppearanceFontTextStyleTitle];
    self.titleLabel.text = homeSectionInfo.title;
    
    self.navigationButton.tintColor = titleTextColor;
    self.navigationButton.hidden = ! [homeSectionInfo canOpenList] || ! self.titleLabel.text;
}

#pragma mark Overrides

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.moduleBackgroundView.backgroundColor = UIColor.clearColor;
    
    self.titleLabel.textColor = UIColor.whiteColor;
    self.titleLabel.userInteractionEnabled = YES;
    
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(openMediaList:)];
    [self.titleLabel addGestureRecognizer:tapGestureRecognizer];
    
    self.navigationButton.tintColor = UIColor.whiteColor;
}

#pragma mark Accessibility

- (BOOL)isAccessibilityElement
{
    return YES;
}

- (NSString *)accessibilityLabel
{
    return self.homeSectionInfo.title;
}

- (NSString *)accessibilityHint
{
    return PlaySRGAccessibilityLocalizedString(@"Shows all contents.", @"Homepage header action hint");
}

- (UIAccessibilityTraits)accessibilityTraits
{
    return UIAccessibilityTraitHeader;
}

#pragma mark Actions

- (IBAction)openMediaList:(id)sender
{
    HomeSectionInfo *homeSectionInfo = self.homeSectionInfo;
    if (! [homeSectionInfo canOpenList]) {
        return;
    }
    
    UIViewController *viewController = nil;
    if (self.homeSectionInfo.module) {
        viewController = [[ModuleViewController alloc] initWithModule:self.homeSectionInfo.module];
    }
    else if ([self.homeSectionInfo.topic isKindOfClass:SRGTopic.class]) {
        viewController = [[HomeTopicViewController alloc] initWithTopic:(SRGTopic *)self.homeSectionInfo.topic];
    }
    else {
        viewController = [[HomeMediasViewController alloc] initWithHomeSectionInfo:homeSectionInfo];
    }
    [self.nearestViewController.navigationController pushViewController:viewController animated:YES];
}

@end
