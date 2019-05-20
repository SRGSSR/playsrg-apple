//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "MyListTableViewCell.h"

#import "AnalyticsConstants.h"
#import "Banner.h"
#import "MyList.h"
#import "NSBundle+PlaySRG.h"
#import "PushService.h"
#import "UIColor+PlaySRG.h"
#import "UIImageView+PlaySRG.h"

#import <CoconutKit/CoconutKit.h>
#import <libextobjc/libextobjc.h>
#import <SRGAnalytics/SRGAnalytics.h>
#import <SRGAppearance/SRGAppearance.h>
#import <SRGUserData/SRGUserData.h>

@interface MyListTableViewCell ()

@property (nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (nonatomic, weak) IBOutlet UIImageView *thumbnailImageView;
@property (nonatomic, weak) IBOutlet UIButton *subscriptionButton;

@end

@implementation MyListTableViewCell

#pragma mark Overrides

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.backgroundColor = UIColor.play_blackColor;
    
    UIView *colorView = [[UIView alloc] init];
    colorView.backgroundColor = UIColor.play_blackColor;
    self.selectedBackgroundView = colorView;
    
    self.thumbnailImageView.backgroundColor = UIColor.play_grayThumbnailImageViewBackgroundColor;
    
    @weakify(self)
    MGSwipeButton *deleteButton = [MGSwipeButton buttonWithTitle:@"" icon:[UIImage imageNamed:@"delete-22"] backgroundColor:UIColor.redColor callback:^BOOL(MGSwipeTableCell * _Nonnull cell) {
        @strongify(self)
        [self.cellDelegate myListTableViewCell:self deleteShow:self.show];
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



- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
    [super traitCollectionDidChange:previousTraitCollection];
    
    [self.nearestViewController registerForPreviewingWithDelegate:self.nearestViewController sourceView:self];
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

#pragma mark UI

- (void)updateSubscriptionStatus
{
    if (PushService.sharedService.enabled) {
        BOOL subscribed = MyListIsSubscribedToShow(self.show);
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
    return (! self.editing) ? self.show : nil;
}

#pragma mark Actions

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
        [self updateSubscriptionStatus];
    }
}

@end
