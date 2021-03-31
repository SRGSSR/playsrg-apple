//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "HomeShowsAccessTableViewCell.h"

#import "ApplicationConfiguration.h"
#import "CalendarViewController.h"
#import "Layout.h"
#import "NSBundle+PlaySRG.h"
#import "ShowsViewController.h"
#import "UIColor+PlaySRG.h"
#import "UILabel+PlaySRG.h"
#import "UIView+PlaySRG.h"
#import "UIViewController+PlaySRG.h"

@import SRGAppearance;

@interface HomeShowsAccessTableViewCell ()

@property (nonatomic, readonly, getter=isDataAvailable) BOOL dataAvailable;

@property (nonatomic, weak) IBOutlet UIView *mainView;
@property (nonatomic, weak) IBOutlet UIView *placeholderView;

@property (nonatomic, weak) IBOutlet UIView *showsAtoZButtonPlaceholderView;
@property (nonatomic, weak) IBOutlet UIView *showsByDateButtonPlaceholderView;

@property (nonatomic, weak) IBOutlet UIButton *showsAtoZButton;
@property (nonatomic, weak) IBOutlet UIButton *showsByDateButton;

@end

@implementation HomeShowsAccessTableViewCell

#pragma mark Class overrides

+ (CGFloat)heightForHomeSectionInfo:(HomeSectionInfo *)homeSectionInfo bounds:(CGRect)bounds featured:(BOOL)featured
{
    return 50.f;
}

#pragma mark Overrides

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.backgroundColor = UIColor.play_blackColor;
    self.selectedBackgroundView.backgroundColor = UIColor.clearColor;
    
    self.mainView.hidden = YES;
    self.placeholderView.hidden = NO;
    
    self.showsAtoZButtonPlaceholderView.backgroundColor = UIColor.play_cardGrayBackgroundColor;
    self.showsAtoZButtonPlaceholderView.layer.cornerRadius = LayoutStandardViewCornerRadius;
    self.showsAtoZButtonPlaceholderView.layer.masksToBounds = YES;
    
    self.showsByDateButtonPlaceholderView.backgroundColor = UIColor.play_cardGrayBackgroundColor;
    self.showsByDateButtonPlaceholderView.layer.cornerRadius = LayoutStandardViewCornerRadius;
    self.showsByDateButtonPlaceholderView.layer.masksToBounds = YES;
    
    self.showsAtoZButton.backgroundColor = UIColor.play_cardGrayBackgroundColor;
    self.showsAtoZButton.layer.cornerRadius = LayoutStandardViewCornerRadius;
    self.showsAtoZButton.layer.masksToBounds = YES;
    [self.showsAtoZButton setTitle:NSLocalizedString(@"A to Z", @"Short title displayed in home pages on a button.") forState:UIControlStateNormal];
    self.showsAtoZButton.accessibilityLabel = PlaySRGAccessibilityLocalizedString(@"A to Z shows", @"Title pronounced in home pages on shows A to Z button.");
    
    self.showsByDateButton.backgroundColor = UIColor.play_cardGrayBackgroundColor;
    self.showsByDateButton.layer.cornerRadius = LayoutStandardViewCornerRadius;
    self.showsByDateButton.layer.masksToBounds = YES;
    [self.showsByDateButton setTitle:NSLocalizedString(@"By date", @"Short title displayed in home pages on a button.") forState:UIControlStateNormal];
    self.showsByDateButton.accessibilityLabel = PlaySRGAccessibilityLocalizedString(@"Shows by date", @"Title pronounced in home pages on shows by date button.");
}

- (void)reloadData
{
    [super reloadData];
    
    if (! self.dataAvailable) {
        self.mainView.hidden = YES;
        self.placeholderView.hidden = NO;
        return;
    }
    
    self.mainView.hidden = NO;
    self.placeholderView.hidden = YES;
    
    self.showsAtoZButton.titleLabel.font = [SRGFont fontWithStyle:SRGFontStyleBody];
    self.showsByDateButton.titleLabel.font = [SRGFont fontWithStyle:SRGFontStyleBody];
}

#pragma mark Accessibility

- (BOOL)isAccessibilityElement
{
    return NO;
}

- (NSArray *)accessibilityElements
{
    return self.dataAvailable ? @[self.showsAtoZButton, self.showsByDateButton] : nil;
}

#pragma mark UI

- (BOOL)isDataAvailable
{
    if (self.homeSectionInfo.homeSection == HomeSectionRadioShowsAccess) {
        return ([[ApplicationConfiguration sharedApplicationConfiguration] radioChannelForUid:self.homeSectionInfo.identifier] != nil);
    }
    else {
        return YES;
    }
}

#pragma mark Actions

- (IBAction)openShowsAZ:(id)sender
{
    RadioChannel *radioChannel = [[ApplicationConfiguration sharedApplicationConfiguration] radioChannelForUid:self.homeSectionInfo.identifier];
    UIViewController *viewController = [[ShowsViewController alloc] initWithRadioChannel:radioChannel alphabeticalIndex:nil];
    [self.play_nearestViewController.navigationController pushViewController:viewController animated:YES];
}

- (IBAction)openShowsByDate:(id)sender
{
    RadioChannel *radioChannel = [[ApplicationConfiguration sharedApplicationConfiguration] radioChannelForUid:self.homeSectionInfo.identifier];
    UIViewController *viewController = [[CalendarViewController alloc] initWithRadioChannel:radioChannel date:nil];
    [self.play_nearestViewController.navigationController pushViewController:viewController animated:YES];
}

@end
