//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "ShowHeaderView.h"

#import "AnalyticsConstants.h"
#import "Banner.h"
#import "MyList.h"
#import "NSBundle+PlaySRG.h"
#import "UIImage+PlaySRG.h"
#import "UIImageView+PlaySRG.h"

#import <SRGAnalytics/SRGAnalytics.h>
#import <SRGAppearance/SRGAppearance.h>
#import <SRGUserData/SRGUserData.h>

// Choose the good aspect ratio for the logo image view, depending of the screen size
static const UILayoutPriority LogoImageViewAspectRatioConstraintNormalPriority = 900;
static const UILayoutPriority LogoImageViewAspectRatioConstraintLowPriority = 700;

@interface ShowHeaderView ()

@property (nonatomic, weak) IBOutlet UIImageView *logoImageView;
@property (nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (nonatomic, weak) IBOutlet UIButton *myListImageButton;
@property (nonatomic, weak) IBOutlet UIButton *myListLabelButton;
@property (nonatomic, weak) IBOutlet UIButton *subscriptionButton;
@property (nonatomic, weak) IBOutlet UILabel *subtitleLabel;

@property (nonatomic) IBOutlet NSLayoutConstraint *logoImageViewRatio16_9Constraint; // Need to retain it, because active state removes it
@property (nonatomic) IBOutlet NSLayoutConstraint *logoImageViewRatioBigLandscapeScreenConstraint; // Need to retain it, because active state removes it

@property (nonatomic, assign) BOOL favoriteState;

@end

@implementation ShowHeaderView

#pragma mark Class methods

+ (CGFloat)heightForShow:(SRGShow *)show withSize:(CGSize)size
{
    // No header displayed on compact vertical layouts
    UITraitCollection *traitCollection = UIApplication.sharedApplication.keyWindow.traitCollection;
    if (traitCollection.verticalSizeClass == UIUserInterfaceSizeClassCompact) {
        return 0.f;
    }
    
    ShowHeaderView *headerView = [NSBundle.mainBundle loadNibNamed:NSStringFromClass(self) owner:nil options:nil].firstObject;
    headerView.show = show;
    
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
    
    self.backgroundColor = UIColor.clearColor;
    
    // Accommodate all kinds of usages
    self.logoImageView.image = [UIImage play_vectorImageAtPath:FilePathForImagePlaceholder(ImagePlaceholderMediaList)
                                                     withScale:ImageScaleLarge];
    
    self.myListImageButton.accessibilityElementsHidden = YES;
}

- (void)layoutSubviews
{
    // To get a correct intrinsic size for a multiline label, we need to set its preferred max layout width
    // (also when using -systemLayoutSizeFittingSize:withHorizontalFittingPriority:verticalFittingPriority:)
    self.subtitleLabel.preferredMaxLayoutWidth = CGRectGetWidth(self.subtitleLabel.frame);
}

- (void)willMoveToWindow:(UIWindow *)newWindow
{
    [super willMoveToWindow:newWindow];
    
    if (newWindow) {
        // Ensure proper state when the view is reinserted
        [self updateMyListStatus];
        [self updateSubscriptionStatus];
        
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(preferencesStateDidChange:)
                                                   name:SRGPreferencesDidChangeNotification
                                                 object:SRGUserData.currentUserData.preferences];
    }
    else {
        [NSNotificationCenter.defaultCenter removeObserver:self name:SRGPreferencesDidChangeNotification object:SRGUserData.currentUserData.preferences];
    }
}

#pragma mark Getters and setters

- (void)setShow:(SRGShow *)show
{
    _show = show;
    
    self.titleLabel.font = [UIFont srg_mediumFontWithTextStyle:SRGAppearanceFontTextStyleTitle];
    self.titleLabel.text = show.title;
    
    self.subtitleLabel.font = [UIFont srg_regularFontWithTextStyle:SRGAppearanceFontTextStyleBody];
    self.subtitleLabel.text = show.lead;
    
    [self.logoImageView play_requestImageForObject:show withScale:ImageScaleLarge type:SRGImageTypeDefault placeholder:ImagePlaceholderMediaList];
    
    [self updateMyListStatus];
    [self updateSubscriptionStatus];
}

#pragma mark UI

- (void)updateMyListStatus
{
    BOOL inMyList = MyListContainsShow(self.show);
    [self.myListImageButton setImage:inMyList ? [UIImage imageNamed:@"my_list_full_show_page-22"] : [UIImage imageNamed:@"my_list_show_page-22"] forState:UIControlStateNormal];
    
    NSDictionary *attributes = @{ NSFontAttributeName : [UIFont srg_regularFontWithTextStyle:SRGAppearanceFontTextStyleSubtitle],
                                  NSForegroundColorAttributeName : UIColor.whiteColor };
    NSString *title = [inMyList ? NSLocalizedString(@"Remove from My List", @"My List show removal label in the show view") : NSLocalizedString(@"Add to My List", @"My List show insertion label in the show view") uppercaseString];
    [self.myListLabelButton setAttributedTitle:[[NSAttributedString alloc] initWithString:title
                                                                               attributes:attributes] forState:UIControlStateNormal];
}

- (void)updateSubscriptionStatus
{
    BOOL inMyList =  MyListContainsShow(self.show);
    self.subscriptionButton.hidden = ! inMyList;
    
    if (! inMyList) {
        return;
    }
    
    BOOL subscribed = MyListIsSubscribedToShow(self.show);
    [self.subscriptionButton setImage:subscribed ? [UIImage imageNamed:@"subscription_full-22"] : [UIImage imageNamed:@"subscription-22"]
                             forState:UIControlStateNormal];
    self.subscriptionButton.accessibilityLabel = subscribed ? PlaySRGAccessibilityLocalizedString(@"Disable notifications for show", @"Show unsubscription label") : PlaySRGAccessibilityLocalizedString(@"Enable notifications for show", @"Show subscription label");
}

- (void)updateAspectRatioWithSize:(CGSize)size
{
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

#pragma mark Actions

- (IBAction)toggleMyList:(id)sender
{
    MyListToggleShow(self.show);
    BOOL inMyList = MyListContainsShow(self.show);
    
    AnalyticsTitle analyticsTitle = inMyList? AnalyticsTitleMyListAdd : AnalyticsTitleMyListRemove;
    SRGAnalyticsHiddenEventLabels *labels = [[SRGAnalyticsHiddenEventLabels alloc] init];
    labels.source = AnalyticsSourceButton;
    labels.value = self.show.URN;
    [SRGAnalyticsTracker.sharedTracker trackHiddenEventWithName:analyticsTitle labels:labels];
    
    [Banner showMyList:inMyList forItemWithName:self.show.title inView:self];
}

- (IBAction)toggleSubscription:(id)sender
{
    BOOL toggled = MyListToggleSubscriptionForShow(self.show, self);
    if (! toggled) {
        return;
    }
    
    BOOL subscribed = MyListIsSubscribedToShow(self.show);
    
    AnalyticsTitle analyticsTitle = (subscribed) ? AnalyticsTitleSubscriptionAdd : AnalyticsTitleSubscriptionRemove;
    SRGAnalyticsHiddenEventLabels *labels = [[SRGAnalyticsHiddenEventLabels alloc] init];
    labels.source = AnalyticsSourceButton;
    labels.value = self.show.URN;
    [SRGAnalyticsTracker.sharedTracker trackHiddenEventWithName:analyticsTitle labels:labels];
    
    [Banner showSubscription:subscribed forShowWithName:self.show.title inView:self];
}

#pragma mark Notifications

- (void)preferencesStateDidChange:(NSNotification *)notification
{
    NSSet<NSString *> *domains = notification.userInfo[SRGPreferencesDomainsKey];
    if ([domains containsObject:PlayPreferenceDomain]) {
        [self updateMyListStatus];
        [self updateSubscriptionStatus];
    }
}

@end
