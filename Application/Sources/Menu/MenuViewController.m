//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "MenuViewController.h"

#import "ApplicationConfiguration.h"
#import "ContentInsets.h"
#import "MenuAccountHeaderView.h"
#import "MenuHeaderSectionView.h"
#import "MenuTableViewCell.h"
#import "NSBundle+PlaySRG.h"
#import "UIViewController+PlaySRG.h"

#import <SRGIdentity/SRGIdentity.h>

@interface MenuViewController ()

@property (nonatomic) NSArray<MenuSectionInfo *> *sectionInfos;

@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, weak) IBOutlet UILabel *versionLabel;

@end

@implementation MenuViewController

#pragma mark Object lifecycle

- (instancetype)init
{
    if (self = [super init]) {
        self.sectionInfos = MenuSectionInfo.currentMenuSectionInfos;
        self.selectedMenuItemInfo = [MenuItemInfo menuItemInfoWithMenuItem:MenuItemUnknown];
    }
    return self;
}

#pragma mark Getters and setters

- (void)setSelectedMenuItemInfo:(MenuItemInfo *)menuItemInfo
{
    _selectedMenuItemInfo = menuItemInfo;
    [self.tableView reloadData];
}

#pragma mark View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tableView.indicatorStyle = UIScrollViewIndicatorStyleWhite;
    
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    
    if (SRGIdentityService.currentIdentityService) {
        self.tableView.tableHeaderView = [MenuAccountHeaderView view];
    }
    
    Class headerClass = MenuHeaderSectionView.class;
    [self.tableView registerClass:MenuHeaderSectionView.class forHeaderFooterViewReuseIdentifier:NSStringFromClass(headerClass)];
    
    NSString *bundleDisplayName = [NSBundle.mainBundle.infoDictionary objectForKey:@"CFBundleDisplayName"];
    NSString *versionString = [NSBundle.mainBundle.infoDictionary objectForKey:@"CFBundleShortVersionString"];
    NSString *bundleVersion = [NSBundle.mainBundle.infoDictionary objectForKey:@"CFBundleVersion"];
    
    // Fixed font size
    self.versionLabel.alpha = 0.f;

    NSString *versionDescription = [NSString stringWithFormat:@"%@ - v. %@ (%@)", bundleDisplayName, versionString, bundleVersion];
    if (NSBundle.mainBundle.testFlightDistribution) {
        versionDescription = [versionDescription stringByAppendingString:@" - TestFlight"];
    }
    self.versionLabel.text = versionDescription;
    
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(accessibilityVoiceOverStatusChanged:)
                                               name:UIAccessibilityVoiceOverStatusChanged
                                             object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(applicationConfigurationDidChange:)
                                               name:ApplicationConfigurationDidChangeNotification
                                             object:nil];
}

#pragma mark Rotation

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return [super supportedInterfaceOrientations] & UIViewController.play_supportedInterfaceOrientations;
}

#pragma mark Status bar

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

#pragma mark Accessibility

- (void)updateForContentSizeCategory
{
    [super updateForContentSizeCategory];
    
    [self.tableView reloadData];
}

#pragma mark UI

- (void)focus
{
    [self.tableView flashScrollIndicators];
    
    // Put the accessibility focus on the currently selected cell
    for (MenuSectionInfo *sectionInfo in self.sectionInfos) {
        NSUInteger row = [sectionInfo.menuItemInfos indexOfObject:self.selectedMenuItemInfo];
        if (row != NSNotFound) {
            NSUInteger section = [self.sectionInfos indexOfObject:sectionInfo];
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:section];
            UITableViewCell *selectedCell = [self.tableView cellForRowAtIndexPath:indexPath];
            UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, selectedCell);
            break;
        }
    }
}

- (void)scrollToTopAnimated:(BOOL)animated
{
    [self.tableView setContentOffset:CGPointMake(0, -self.tableView.contentInset.top) animated:animated];
}

#pragma mark UIScrollViewDelegate protocol

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    // The version label is hidden and displayed if we scroll the view further than its bottom
    [UIView animateWithDuration:0.1 animations:^{
        static const CGFloat kOffsetThreshold = 120.f;
        
        UIEdgeInsets contentInsets = ContentInsetsForScrollView(scrollView);
        BOOL offsetThresholdReached = (scrollView.contentOffset.y + CGRectGetHeight(scrollView.frame) - contentInsets.top - contentInsets.bottom > fmaxf(scrollView.contentSize.height, CGRectGetHeight(scrollView.frame)) + kOffsetThreshold);
        self.versionLabel.alpha = offsetThresholdReached ? 1.f : 0.f;
    }];
}

#pragma mark UITableViewDataSource protocol

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.sectionInfos.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.sectionInfos[section].menuItemInfos.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [tableView dequeueReusableCellWithIdentifier:NSStringFromClass(MenuTableViewCell.class) forIndexPath:indexPath];
}

#pragma mark UITableViewDelegate protocol

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 50.f;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(MenuTableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    MenuItemInfo *menuItemInfo = self.sectionInfos[indexPath.section].menuItemInfos[indexPath.row];
    cell.menuItemInfo = menuItemInfo;
    cell.current = [self.selectedMenuItemInfo isEqual:menuItemInfo];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    MenuItemInfo *menuItemInfo = self.sectionInfos[indexPath.section].menuItemInfos[indexPath.row];
    self.selectedMenuItemInfo = menuItemInfo;
    [self.delegate menuViewController:self didSelectMenuItemInfo:menuItemInfo];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    MenuSectionInfo *sectionInfo = self.sectionInfos[section];
    return [MenuHeaderSectionView heightForMenuSectionInfo:sectionInfo];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    MenuHeaderSectionView *headerView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:NSStringFromClass(MenuHeaderSectionView.class)];
    headerView.menuSectionInfo = self.sectionInfos[section];
    return headerView;
}

#pragma mark Notifications

- (void)accessibilityVoiceOverStatusChanged:(NSNotification *)notification
{
    [self.tableView reloadData];
}

- (void)applicationConfigurationDidChange:(NSNotification *)notification
{
    self.sectionInfos = MenuSectionInfo.currentMenuSectionInfos;
    [self.tableView reloadData];
    
    // Do not update selectedMenuItemInfo. If now invalid, it must not be visibly selected after all. A correct value
    // will be set the next time the user selects a menu item
}

@end
