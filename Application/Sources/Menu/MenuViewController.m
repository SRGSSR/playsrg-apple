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
#import "UIScrollView+PlaySRG.h"
#import "UIViewController+PlaySRG.h"

#import <SRGIdentity/SRGIdentity.h>

@interface MenuViewController ()

@property (nonatomic) NSArray<MenuSectionInfo *> *sectionInfos;

@property (nonatomic, weak) IBOutlet UITableView *tableView;

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
    [self.tableView play_scrollToTopAnimated:animated];
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
