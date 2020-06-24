//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SettingsBaseViewController.h"

#import "SettingTableViewCell.h"
#import "UIColor+PlaySRG.h"
#import "UIViewController+PlaySRG.h"

#import "InAppSettingsKit/IASKSettingsReader.h"
#import <objc/runtime.h>
#import <SRGAppearance/SRGAppearance.h>

@implementation SettingsBaseViewController

#pragma mark Object lifecycle

- (instancetype)init
{
    if (self = [super init]) {
        self.delegate = self;
        
        self.showDoneButton = NO;
        self.showCreditsFooter = NO;
    }
    return self;
}

#pragma mark View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tableView.estimatedRowHeight = 0.f;
    self.tableView.estimatedSectionHeaderHeight = 0.f;
    self.tableView.estimatedSectionFooterHeight = 0.f;
    
    self.view.backgroundColor = UIColor.play_blackColor;
    self.tableView.separatorColor = UIColor.play_grayColor;
    
    self.neverShowPrivacySettings = YES;
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

#pragma mark ContentInsets protocol

- (NSArray<UIScrollView *> *)play_contentScrollViews
{
    return self.tableView ? @[self.tableView] : nil;
}

- (UIEdgeInsets)play_paddingContentInsets
{
    return UIEdgeInsetsZero;
}

#pragma mark IASKSettingsDelegate protocol

- (void)settingsViewControllerDidEnd:(IASKAppSettingsViewController *)settingsViewController
{}

- (UIView *)settingsViewController:(id<IASKViewController>)settingsViewController viewForHeaderInSection:(NSInteger)section specifier:(IASKSpecifier *)specifier
{
    // We must return a view for the header so that the height delegate method gets called
    return [[UITableViewHeaderFooterView alloc] initWithFrame:CGRectZero];
}

- (CGFloat)settingsViewController:(UITableViewController<IASKViewController> *)settingsViewController heightForHeaderInSection:(NSInteger)section specifier:(IASKSpecifier *)specifier
{
    BOOL hasTitle = [self tableView:settingsViewController.tableView titleForHeaderInSection:section].length != 0;
    if (section == 0) {
        return hasTitle ? 75.f : 15.f;
    }
    else {
        return hasTitle ? 60.f : 0.1f /* Cannot use 0 = automatic dimension */;
    }
}

- (UIView *)settingsViewController:(UITableViewController<IASKViewController> *)settingsViewController viewForFooterInSection:(NSInteger)section specifier:(IASKSpecifier *)specifier
{
    // We must return a view for the footer so that the height delegate method gets called
    return [[UITableViewHeaderFooterView alloc] initWithFrame:CGRectZero];
}

- (CGFloat)settingsViewController:(UITableViewController<IASKViewController> *)settingsViewController heightForFooterInSection:(NSInteger)section specifier:(IASKSpecifier *)specifier
{
    BOOL hasFooter = [self tableView:settingsViewController.tableView titleForFooterInSection:section].length != 0;
    return hasFooter ? UITableViewAutomaticDimension : 0.1f /* Cannot use 0 = automatic dimension */;
}

#pragma mark UITableViewDelegate protocol

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // For cells with a standard (in our case ugly) selection effect, replace with a custom cell subclass
    // providing a better effect.
    UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
    if (cell.selectionStyle != UITableViewCellSelectionStyleNone) {
        object_setClass(cell, SettingTableViewCell.class);
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    cell.backgroundColor = [UIColor colorWithWhite:1.f alpha:0.02f];
    cell.textLabel.font = [UIFont srg_mediumFontWithTextStyle:SRGAppearanceFontTextStyleBody];
    cell.textLabel.textColor = UIColor.whiteColor;
    cell.detailTextLabel.font = [UIFont srg_regularFontWithTextStyle:SRGAppearanceFontTextStyleBody];
    cell.tintColor = UIColor.whiteColor;
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UITableViewHeaderFooterView *)view forSection:(NSInteger)section
{
    view.textLabel.font = [UIFont srg_mediumFontWithTextStyle:SRGAppearanceFontTextStyleTitle];
    view.textLabel.textColor = UIColor.play_lightGrayColor;
}

- (void)tableView:(UITableView *)tableView willDisplayFooterView:(UITableViewHeaderFooterView *)view forSection:(NSInteger)section
{
    view.textLabel.font = [UIFont srg_mediumFontWithTextStyle:SRGAppearanceFontTextStyleSubtitle];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [super tableView:tableView didSelectRowAtIndexPath:indexPath];
    
    // Fix ugly behavior of InAppSettingsKit
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
