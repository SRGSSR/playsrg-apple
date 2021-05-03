//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "OnboardingsViewController.h"

#import "AnalyticsConstants.h"
#import "Onboarding.h"
#import "OnboardingTableViewCell.h"
#import "Play-Swift-Bridge.h"
#import "TableView.h"
#import "UIColor+PlaySRG.h"
#import "UIViewController+PlaySRG.h"

@import SRGAppearance;

@interface OnboardingsViewController ()

@property (nonatomic) NSArray<Onboarding *> *onboardings;

@property (nonatomic, weak) IBOutlet UITableView *tableView;

@end

@implementation OnboardingsViewController

#pragma mark View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.onboardings = Onboarding.onboardings;
    self.title = NSLocalizedString(@"Features", @"Title displayed at the top of the features list");
    
    self.view.backgroundColor = UIColor.play_blackColor;
    
    TableViewConfigure(self.tableView);
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
}

#pragma mark Rotation

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return [super supportedInterfaceOrientations] & UIViewController.play_supportedInterfaceOrientations;
}

#pragma mark Accessibility

- (void)updateForContentSizeCategory
{
    [super updateForContentSizeCategory];
    
    [self.tableView reloadData];
}

#pragma mark Status bar

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

#pragma mark SRGAnalyticsViewTracking protocol

- (NSString *)srg_pageViewTitle
{
    return AnalyticsPageTitleFeatures;
}

- (NSArray<NSString *> *)srg_pageViewLevels
{
    return @[ AnalyticsPageLevelPlay, AnalyticsPageLevelApplication ];
}

#pragma mark UITableViewDataSource protocol

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.onboardings.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [tableView dequeueReusableCellWithIdentifier:NSStringFromClass(OnboardingTableViewCell.class)];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return NSLocalizedString(@"Discover", @"Introductory title displayed at the top of the onboarding list");
}

#pragma mark UITableViewDelegate protocol

- (void)tableView:(UITableView *)tableView willDisplayCell:(OnboardingTableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    cell.onboarding = self.onboardings[indexPath.row];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    Onboarding *onboarding = self.onboardings[indexPath.row];
    OnboardingViewController *onboardingViewController = [OnboardingViewController viewControllerFor:onboarding];
    onboardingViewController.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:onboardingViewController animated:YES completion:nil];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 44.f;
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UITableViewHeaderFooterView *)view forSection:(NSInteger)section
{
    view.textLabel.font = [SRGFont fontWithStyle:SRGFontStyleH2];
    view.textLabel.textColor = UIColor.play_lightGrayColor;
    
    UIView *backgroundView = [[UIView alloc] init];
    backgroundView.backgroundColor = UIColor.play_blackColor;
    view.backgroundView = backgroundView;
}

@end
