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

static const CGFloat HomeSectionHeaderMinimumHeight = 10.f;

@interface HomeSectionHeaderView ()

@property (nonatomic, weak) IBOutlet UIView *moduleBackgroundView;
@property (nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (nonatomic, weak) IBOutlet UIButton *navigationButton;

@property (nonatomic) HomeSectionInfo *homeSectionInfo;
@property (nonatomic, getter=isFeatured) BOOL featured;

@end

@implementation HomeSectionHeaderView

#pragma mark Class methods

+ (CGFloat)heightForHomeSectionInfo:(HomeSectionInfo *)homeSectionInfo bounds:(CGRect)bounds featured:(BOOL)featured
{
    if (featured) {
        ApplicationConfiguration *applicationConfiguration = ApplicationConfiguration.sharedApplicationConfiguration;
        BOOL isRadioChannel = ([applicationConfiguration radioChannelForUid:homeSectionInfo.identifier] != nil);
        BOOL isHomeFeaturedHeaderHidden = isRadioChannel ? applicationConfiguration.radioFeaturedHomeSectionHeaderHidden : applicationConfiguration.tvFeaturedHomeSectionHeaderHidden;
        
        if (! UIAccessibilityIsVoiceOverRunning() && isHomeFeaturedHeaderHidden) {
            return 10.f;
        }
        else {
            static NSDictionary<NSString *, NSNumber *> *s_headerHeights;
            static dispatch_once_t s_onceToken;
            dispatch_once(&s_onceToken, ^{
                s_headerHeights = @{ UIContentSizeCategoryExtraSmall : @40,
                                     UIContentSizeCategorySmall : @45,
                                     UIContentSizeCategoryMedium : @45,
                                     UIContentSizeCategoryLarge : @45,
                                     UIContentSizeCategoryExtraLarge : @50,
                                     UIContentSizeCategoryExtraExtraLarge : @55,
                                     UIContentSizeCategoryExtraExtraExtraLarge : @55,
                                     UIContentSizeCategoryAccessibilityMedium : @55,
                                     UIContentSizeCategoryAccessibilityLarge : @55,
                                     UIContentSizeCategoryAccessibilityExtraLarge : @55,
                                     UIContentSizeCategoryAccessibilityExtraExtraLarge : @55,
                                     UIContentSizeCategoryAccessibilityExtraExtraExtraLarge : @55 };
            });
            
            NSString *contentSizeCategory = UIApplication.sharedApplication.preferredContentSizeCategory;
            return s_headerHeights[contentSizeCategory].floatValue;
        }
    }
    else {
        static NSDictionary<NSString *, NSNumber *> *s_headerHeights;
        static dispatch_once_t s_onceToken;
        dispatch_once(&s_onceToken, ^{
            s_headerHeights = @{ UIContentSizeCategoryExtraSmall : @30,
                                 UIContentSizeCategorySmall : @35,
                                 UIContentSizeCategoryMedium : @40,
                                 UIContentSizeCategoryLarge : @45,
                                 UIContentSizeCategoryExtraLarge : @45,
                                 UIContentSizeCategoryExtraExtraLarge : @45,
                                 UIContentSizeCategoryExtraExtraExtraLarge : @50,
                                 UIContentSizeCategoryAccessibilityMedium : @50,
                                 UIContentSizeCategoryAccessibilityLarge : @50,
                                 UIContentSizeCategoryAccessibilityExtraLarge : @50,
                                 UIContentSizeCategoryAccessibilityExtraExtraLarge : @50,
                                 UIContentSizeCategoryAccessibilityExtraExtraExtraLarge : @50 };
        });
        
        NSString *contentSizeCategory = UIApplication.sharedApplication.preferredContentSizeCategory;
        return s_headerHeights[contentSizeCategory].floatValue;
    }
}

#pragma mark Getters and setters

- (void)setHomeSectionInfo:(HomeSectionInfo *)homeSectionInfo featured:(BOOL)featured
{
    self.homeSectionInfo = homeSectionInfo;
    self.featured = featured;
    
    UIColor *backgroundColor = UIColor.clearColor;
    UIColor *titleTextColor = UIColor.whiteColor;
    if (homeSectionInfo.module && ! ApplicationConfiguration.sharedApplicationConfiguration.moduleColorsDisabled) {
        backgroundColor = homeSectionInfo.module.backgroundColor;
        titleTextColor = homeSectionInfo.module.linkColor ?: ApplicationConfiguration.sharedApplicationConfiguration.moduleDefaultLinkColor;
    }
    
    self.moduleBackgroundView.backgroundColor = backgroundColor;
    
    self.titleLabel.textColor = titleTextColor;
    self.titleLabel.font = [UIFont srg_mediumFontWithTextStyle:SRGAppearanceFontTextStyleTitle];
    self.titleLabel.text = ([HomeSectionHeaderView heightForHomeSectionInfo:homeSectionInfo bounds:self.bounds featured:featured] > HomeSectionHeaderMinimumHeight) ? homeSectionInfo.title : nil;
    
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
