//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "FavoriteTableViewCell.h"

#import "AnalyticsConstants.h"
#import "Banner.h"
#import "Favorites.h"
#import "NSBundle+PlaySRG.h"
#import "PushService.h"
#import "UIColor+PlaySRG.h"
#import "UIImageView+PlaySRG.h"

#import <libextobjc/libextobjc.h>
#import <SRGAnalytics/SRGAnalytics.h>
#import <SRGAppearance/SRGAppearance.h>
#import <SRGUserData/SRGUserData.h>

@interface FavoriteTableViewCell ()

@property (nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (nonatomic, weak) IBOutlet UIImageView *thumbnailImageView;
@property (nonatomic, weak) IBOutlet UIButton *subscriptionButton;

@end

@implementation FavoriteTableViewCell

#pragma mark Overrides

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    UIColor *backgroundColor = UIColor.play_blackColor;
    self.backgroundColor = backgroundColor;
    
    UIView *colorView = [[UIView alloc] init];
    colorView.backgroundColor = backgroundColor;
    self.selectedBackgroundView = colorView;
    
    self.titleLabel.backgroundColor = backgroundColor;
    
    self.thumbnailImageView.backgroundColor = UIColor.play_grayThumbnailImageViewBackgroundColor;
    
    @weakify(self)
    MGSwipeButton *deleteButton = [MGSwipeButton buttonWithTitle:@"" icon:[UIImage imageNamed:@"delete-22"] backgroundColor:UIColor.redColor callback:^BOOL(MGSwipeTableCell * _Nonnull cell) {
        @strongify(self)
        [self.cellDelegate favoriteTableViewCell:self deleteShow:self.show];
        return YES;
    }];
    deleteButton.tintColor = UIColor.whiteColor;
    deleteButton.buttonWidth = 60.f;
    self.rightButtons = @[deleteButton];
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    
    [self.thumbnailImageView play_resetImage];
}

- (void)willMoveToWindow:(UIWindow *)newWindow
{
    [super willMoveToWindow:newWindow];
    
    if (newWindow) {
        // Ensure proper state when the view is reinserted
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

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];
    
    self.selectionStyle = editing ? UITableViewCellSelectionStyleDefault : UITableViewCellSelectionStyleNone;
    if (editing && self.swipeState != MGSwipeStateNone) {
        [self hideSwipeAnimated:animated];
    }
}

#pragma mark Getters and setters

- (void)setShow:(SRGShow *)show
{
    _show = show;
    
    self.titleLabel.text = show.title;
    self.titleLabel.font = [UIFont srg_mediumFontWithTextStyle:SRGAppearanceFontTextStyleBody];
    
    [self.thumbnailImageView play_requestImageForObject:show withScale:ImageScaleSmall type:SRGImageTypeDefault placeholder:ImagePlaceholderMediaList];
    
    [self updateSubscriptionStatus];
}

#pragma mark Accessibility

- (BOOL)isAccessibilityElement
{
    return YES;
}

#pragma mark UI

- (void)updateSubscriptionStatus
{
    if (PushService.sharedService.enabled) {
        BOOL subscribed = FavoritesIsSubscribedToShow(self.show);
        [self.subscriptionButton setImage:subscribed ? [UIImage imageNamed:@"subscription_full-22"] : [UIImage imageNamed:@"subscription-22"]
                                 forState:UIControlStateNormal];
        self.subscriptionButton.accessibilityLabel = subscribed ? PlaySRGAccessibilityLocalizedString(@"Disable notifications for show", @"Show unsubscription label") : PlaySRGAccessibilityLocalizedString(@"Enable notifications for show", @"Show subscription label");
    }
    else {
        [self.subscriptionButton setImage:[UIImage imageNamed:@"subscription_disabled-22"] forState:UIControlStateNormal];
        self.subscriptionButton.accessibilityLabel = PlaySRGAccessibilityLocalizedString(@"Enable notifications for show", @"Show subscription label");
    }
}

#pragma mark Previewing protocol

- (id)previewObject
{
    return ! self.editing ? self.show : nil;
}

- (NSValue *)previewAnchorRect
{
    CGRect imageViewFrameInSelf = [self.thumbnailImageView convertRect:self.thumbnailImageView.bounds toView:self];
    return [NSValue valueWithCGRect:imageViewFrameInSelf];
}

#pragma mark Actions

- (IBAction)toggleSubscription:(id)sender
{
    BOOL toggled = FavoritesToggleSubscriptionForShow(self.show, self);
    if (! toggled) {
        return;
    }
    
    BOOL subscribed = FavoritesIsSubscribedToShow(self.show);

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
    if ([domains containsObject:PlayPreferencesDomain]) {
        [self updateSubscriptionStatus];
    }
}

@end
