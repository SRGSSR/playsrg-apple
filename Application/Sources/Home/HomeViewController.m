//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "HomeViewController.h"

#import "ApplicationConfiguration.h"
#import "ApplicationSettings.h"
#import "Favorites.h"
#import "HomeSectionHeaderView.h"
#import "HomeMediaListTableViewCell.h"
#import "HomeRadioLiveTableViewCell.h"
#import "HomeSectionInfo.h"
#import "HomeShowListTableViewCell.h"
#import "HomeShowsAccessTableViewCell.h"
#import "HomeShowVerticalListTableViewCell.h"
#import "HomeStatusHeaderView.h"
#import "NavigationController.h"
#import "Notification.h"
#import "NotificationsViewController.h"
#import "NSBundle+PlaySRG.h"
#import "PushService.h"
#import "SearchViewController.h"
#import "UIColor+PlaySRG.h"
#import "UIViewController+PlaySRG.h"

#import <libextobjc/libextobjc.h>
#import <PPBadgeView/PPBadgeView.h>
#import <SRGAppearance/SRGAppearance.h>
#import <SRGDataProvider/SRGDataProvider.h>
#import <SRGUserData/SRGUserData.h>

@interface HomeViewController ()

@property (nonatomic) NSArray<NSNumber *> *homeSections;
@property (nonatomic) RadioChannel *radioChannel;

@property (nonatomic) NSArray<HomeSectionInfo *> *homeSectionInfos;

@property (nonatomic) SRGServiceMessage *serviceMessage;
@property (nonatomic) NSArray<SRGTopic *> *topics;
@property (nonatomic) NSArray<SRGModule *> *eventModules;

@property (nonatomic) NSError *lastRequestError;

@property (nonatomic, weak) UIRefreshControl *refreshControl;
@property (nonatomic, weak) IBOutlet UITableView *tableView;

@property (nonatomic, getter=isTopicsLoaded) BOOL topicsLoaded;
@property (nonatomic, getter=isEventsLoaded) BOOL eventsLoaded;
@property (nonatomic, getter=isFavoriteTVShowsLoaded) BOOL favoriteTVShowsLoaded;
@property (nonatomic, getter=isFavoriteRadioShowsLoaded) BOOL favoriteRadioShowsLoaded;

@end

@implementation HomeViewController

#pragma mark Object lifecycle

- (instancetype)initWithRadioChannel:(RadioChannel *)radioChannel
{
    if (self = [super init]) {
        self.homeSections = (radioChannel) ? radioChannel.homeSections : ApplicationConfiguration.sharedApplicationConfiguration.tvHomeSections;
        self.radioChannel = radioChannel;
        
        [self synchronizeHomeSections];
    }
    return self;
}

#pragma mark View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (self.radioChannel) {
        self.title = self.radioChannel.name;
        self.navigationItem.titleView = [[UIImageView alloc] initWithImage:RadioChannelNavigationBarImage(self.radioChannel)];
    }
    else {
        self.title = NSLocalizedString(@"Overview", @"Home page title");
        self.navigationItem.titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"logo_play-20"]];
    }
    
    self.navigationItem.titleView.isAccessibilityElement = YES;
    self.navigationItem.titleView.accessibilityTraits = UIAccessibilityTraitHeader;
    self.navigationItem.titleView.accessibilityLabel = self.title;
    
    self.view.backgroundColor = UIColor.play_blackColor;
    
    self.tableView.indicatorStyle = UIScrollViewIndicatorStyleWhite;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    
    self.tableView.emptyDataSetSource = self;
    self.tableView.emptyDataSetDelegate = self;
    
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    refreshControl.tintColor = UIColor.whiteColor;
    [refreshControl addTarget:self action:@selector(refresh:) forControlEvents:UIControlEventValueChanged];
    [self.tableView insertSubview:refreshControl atIndex:0];
    self.refreshControl = refreshControl;
    
    NSString *mediaCellIdentifier = NSStringFromClass(HomeMediaListTableViewCell.class);
    UINib *homeMediaListTableViewCellNib = [UINib nibWithNibName:mediaCellIdentifier bundle:nil];
    [self.tableView registerNib:homeMediaListTableViewCellNib forCellReuseIdentifier:mediaCellIdentifier];
    
    NSString *showCellIdentifier = NSStringFromClass(HomeShowListTableViewCell.class);
    UINib *homeShowListTableViewCellNib = [UINib nibWithNibName:showCellIdentifier bundle:nil];
    [self.tableView registerNib:homeShowListTableViewCellNib forCellReuseIdentifier:showCellIdentifier];
    
    NSString *showVerticalListCellIdentifier = NSStringFromClass(HomeShowVerticalListTableViewCell.class);
    UINib *homeShowVerticalListTableViewCellNib = [UINib nibWithNibName:showVerticalListCellIdentifier bundle:nil];
    [self.tableView registerNib:homeShowVerticalListTableViewCellNib forCellReuseIdentifier:showVerticalListCellIdentifier];
    
    NSString *radioLiveCellIdentifier = NSStringFromClass(HomeRadioLiveTableViewCell.class);
    UINib *homeRadioLiveTableViewCellNib = [UINib nibWithNibName:radioLiveCellIdentifier bundle:nil];
    [self.tableView registerNib:homeRadioLiveTableViewCellNib forCellReuseIdentifier:radioLiveCellIdentifier];
    
    NSString *showsAccessCellIdentifier = NSStringFromClass(HomeShowsAccessTableViewCell.class);
    UINib *homeShowsAccessTableViewCellNib = [UINib nibWithNibName:showsAccessCellIdentifier bundle:nil];
    [self.tableView registerNib:homeShowsAccessTableViewCellNib forCellReuseIdentifier:showsAccessCellIdentifier];
    
    NSString *headerIdentifier = NSStringFromClass(HomeSectionHeaderView.class);
    UINib *homeSectionHeaderViewNib = [UINib nibWithNibName:headerIdentifier bundle:nil];
    [self.tableView registerNib:homeSectionHeaderViewNib forHeaderFooterViewReuseIdentifier:headerIdentifier];
    
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(accessibilityVoiceOverStatusChanged:)
                                               name:UIAccessibilityVoiceOverStatusChanged
                                             object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(applicationDidBecomeActive:)
                                               name:UIApplicationDidBecomeActiveNotification
                                             object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(didReceiveNotification:)
                                               name:PushServiceDidReceiveNotification
                                             object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(preferencesStateDidChange:)
                                               name:SRGPreferencesDidChangeNotification
                                             object:SRGUserData.currentUserData.preferences];
    
    [self updateStatusHeaderViewLayout];
    [self.tableView reloadData];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self updateBarButtonItems];
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    
    [self.tableView reloadEmptyDataSet];
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
    
    [self updateStatusHeaderViewLayout];
    [self.tableView reloadData];
}

#pragma mark Status bar

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

#pragma mark Rotation

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        [self updateStatusHeaderViewLayout];
    } completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        // Nothing, block is mandatory
    }];
}

#pragma mark Overrides

- (void)prepareRefreshWithRequestQueue:(SRGRequestQueue *)requestQueue
{
    SRGVendor vendor = ApplicationConfiguration.sharedApplicationConfiguration.vendor;
    
    SRGRequest *serviceMessageRequest = [SRGDataProvider.currentDataProvider serviceMessageForVendor:vendor withCompletionBlock:^(SRGServiceMessage * _Nullable serviceMessage, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
        if (serviceMessage && ! [serviceMessage isEqual:self.serviceMessage]) {
            [self updateStatusHeaderViewLayoutWithMessage:serviceMessage];
            self.serviceMessage = serviceMessage;
        }
        else if ((! serviceMessage || HTTPResponse.statusCode == 404) && self.serviceMessage) {
            [self updateStatusHeaderViewLayoutWithMessage:nil];
            self.serviceMessage = nil;
        }
    }];
    [requestQueue addRequest:serviceMessageRequest resume:YES];
    
    // Start from the layout specified at construction
    for (NSNumber *homeSection in self.homeSections) {
        switch (homeSection.integerValue) {
            case HomeSectionTVTopics: {
                SRGRequest *request = [SRGDataProvider.currentDataProvider tvTopicsForVendor:vendor withCompletionBlock:^(NSArray<SRGTopic *> * _Nullable topics, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
                    if (error) {
                        [requestQueue reportError:error];
                        return;
                    }
                    
                    self.topicsLoaded = YES;
                    
                    self.topics = topics;
                    [self synchronizeHomeSections];
                    [self.tableView reloadData];
                    
                    [self refreshHomeSection:homeSection.integerValue withRequestQueue:requestQueue];
                }];
                [requestQueue addRequest:request resume:YES];
                break;
            }
                
            case HomeSectionTVEvents: {
                SRGRequest *request = [SRGDataProvider.currentDataProvider modulesForVendor:vendor type:SRGModuleTypeEvent withCompletionBlock:^(NSArray<SRGModule *> * _Nullable modules, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
                    if (error) {
                        [requestQueue reportError:error];
                        return;
                    }
                    
                    self.eventsLoaded = YES;
                    
                    NSDate *nowDate = NSDate.date;
                    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(%K <= %@) AND (%K > %@)", @keypath(SRGModule.new, startDate), nowDate, @keypath(SRGModule.new, endDate), nowDate];
                    modules = [modules filteredArrayUsingPredicate:predicate];
                    
                    self.eventModules = modules;
                    [self synchronizeHomeSections];
                    [self.tableView reloadData];
                    
                    [self refreshHomeSection:homeSection.integerValue withRequestQueue:requestQueue];
                }];
                [requestQueue addRequest:request resume:YES];
                break;
            }
                
            default: {
                [self refreshHomeSection:homeSection.integerValue withRequestQueue:requestQueue];
                break;
            }
        }
    }
}

- (void)refreshDidStart
{
    self.lastRequestError = nil;
}

- (void)refreshDidFinishWithError:(NSError *)error
{
    self.lastRequestError = error;
    
    // Avoid stopping scrolling
    // See http://stackoverflow.com/a/31681037/760435
    if (self.refreshControl.refreshing) {
        [self.refreshControl endRefreshing];
    }
    
    [self.tableView reloadData];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView flashScrollIndicators];
    });
}

- (AnalyticsPageType)pageType
{
    return self.radioChannel ? AnalyticsPageTypeRadio : AnalyticsPageTypeTV;
}

#pragma mark User interface

- (void)updateStatusHeaderViewLayout
{
    [self updateStatusHeaderViewLayoutWithMessage:self.serviceMessage];
}

// Table view header height / visibility updates are tricky. We cannot do it every time we reload data, otherwise the
// layout is incorrect. Instead, we need a layout method which we call only when updates are required.
- (void)updateStatusHeaderViewLayoutWithMessage:(SRGServiceMessage *)message
{
    HomeStatusHeaderView *headerView = [HomeStatusHeaderView view];
    headerView.serviceMessage = message;
    
    BOOL hidden = (message == nil);
    CGFloat headerHeight = ! hidden ? [HomeStatusHeaderView heightForServiceMessage:message withSize:self.tableView.frame.size] : 0.1f;
    headerView.frame = CGRectMake(0.f, 0.f, CGRectGetWidth(self.tableView.frame), headerHeight);
    headerView.hidden = hidden;
    
    // Always set a header view. Setting it to nil when no message is displayed does not correctly update the table
    // view. Instead, use an invisible header with length close to 0
    self.tableView.tableHeaderView = headerView;
}

- (void)updateBarButtonItems
{
    NSMutableArray<UIBarButtonItem *> *rightBarButtonItems = [NSMutableArray array];
    
    [PushService.sharedService updateApplicationBadge];
    
    if (@available(iOS 10, *)) {
        if (PushService.sharedService.enabled) {
            UIImage *notificationImage = [UIImage imageNamed:@"subscription_full-22"];
            UIButton *notificationButton = [UIButton buttonWithType:UIButtonTypeCustom];
            notificationButton.frame = CGRectMake(0.f, 0.f, notificationImage.size.width, notificationImage.size.height);
            [notificationButton setImage:notificationImage forState:UIControlStateNormal];
            [notificationButton addTarget:self action:@selector(showNotifications:) forControlEvents:UIControlEventTouchUpInside];
            
            NSInteger badgeNumber = UIApplication.sharedApplication.applicationIconBadgeNumber;
            if (badgeNumber != 0) {
                NSString *badgeText = (badgeNumber > 99) ? @"99+" : @(badgeNumber).stringValue;
                [notificationButton pp_addBadgeWithText:badgeText];
                [notificationButton pp_moveBadgeWithX:-6.f Y:7.f];
                [notificationButton pp_setBadgeHeight:14.f];
                [notificationButton pp_setBadgeLabelAttributes:^(PPBadgeLabel *badgeLabel) {
                    badgeLabel.font = [UIFont boldSystemFontOfSize:13.f];
                    badgeLabel.backgroundColor = UIColor.play_notificationRedColor;
                }];
                
                RadioChannel *radioChannel = self.radioChannel;
                if (radioChannel && ! radioChannel.badgeStrokeHidden) {
                    [notificationButton pp_setBadgeLabelAttributes:^(PPBadgeLabel *badgeLabel) {
                        badgeLabel.layer.borderColor = radioChannel.titleColor.CGColor;
                        badgeLabel.layer.borderWidth = 1.f;
                    }];
                }
            }
            
            UIBarButtonItem *notificationsBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:notificationButton];
            notificationsBarButtonItem.accessibilityLabel = PlaySRGAccessibilityLocalizedString(@"Notifications", @"Notifications button label");
            [rightBarButtonItems addObject:notificationsBarButtonItem];
        }
    }
    
    self.navigationItem.rightBarButtonItems = rightBarButtonItems.copy;
}

#pragma mark Section management

- (void)refreshHomeSection:(HomeSection)homeSection withRequestQueue:(SRGRequestQueue *)requestQueue
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == %@", @keypath(HomeSectionInfo.new, homeSection), @(homeSection)];
    NSArray<HomeSectionInfo *> *homeSectionInfos = [self.homeSectionInfos filteredArrayUsingPredicate:predicate];
    for (HomeSectionInfo *homeSectionInfo in homeSectionInfos) {
        [homeSectionInfo refreshWithRequestQueue:requestQueue completionBlock:^(NSError * _Nullable error) {
            // Refresh as data becomes available for better perceived loading times
            if (! error) {
                if (homeSection == HomeSectionTVFavoriteShows) {
                    self.favoriteTVShowsLoaded = YES;
                    [self synchronizeHomeSections];
                }
                else if (homeSection == HomeSectionRadioFavoriteShows) {
                    self.favoriteRadioShowsLoaded = YES;
                    [self synchronizeHomeSections];
                }
                [self.tableView reloadData];
            }
        }];
    }
}

- (void)synchronizeHomeSections
{
    // Display sections, as well as empty placeholder sections for expected sections (except when they are found to be
    // empty). Start from the layout specified at construction
    NSMutableArray *homeSectionInfos = [NSMutableArray array];
    for (NSNumber *homeSection in self.homeSections) {
        if (homeSection.integerValue == HomeSectionTVTopics) {
            if (self.topics.count != 0) {
                for (SRGTopic *topic in self.topics) {
                    HomeSectionInfo *homeSectionInfo = [self infoForHomeSection:homeSection.integerValue withObject:topic title:topic.title];
                    [homeSectionInfos addObject:homeSectionInfo];
                }
            }
            else if (! self.topicsLoaded) {
                HomeSectionInfo *homeSectionInfo = [self infoForHomeSection:homeSection.integerValue withObject:nil title:TitleForHomeSection(homeSection.integerValue)];
                [homeSectionInfos addObject:homeSectionInfo];
            }
        }
        else if (homeSection.integerValue == HomeSectionTVEvents) {
            if (self.eventModules.count != 0) {
                for (SRGModule *module in self.eventModules) {
                    HomeSectionInfo *homeSectionInfo = [self infoForHomeSection:homeSection.integerValue withObject:module title:module.title];
                    [homeSectionInfos addObject:homeSectionInfo];
                }
            }
            else if (! self.eventsLoaded) {
                HomeSectionInfo *homeSectionInfo = [self infoForHomeSection:homeSection.integerValue withObject:nil title:TitleForHomeSection(homeSection.integerValue)];
                [homeSectionInfos addObject:homeSectionInfo];
            }
        }
        else if (homeSection.integerValue == HomeSectionTVFavoriteShows) {
            HomeSectionInfo *homeSectionInfo = [self infoForHomeSection:homeSection.integerValue withObject:nil title:TitleForHomeSection(homeSection.integerValue)];
            if (homeSectionInfo.items.count != 0) {
                [homeSectionInfos addObject:homeSectionInfo];
            }
            else if (! self.favoriteTVShowsLoaded) {
                [homeSectionInfos addObject:homeSectionInfo];
            }
        }
        else if (homeSection.integerValue == HomeSectionRadioFavoriteShows) {
            HomeSectionInfo *homeSectionInfo = [self infoForHomeSection:homeSection.integerValue withObject:self.radioChannel.uid title:TitleForHomeSection(homeSection.integerValue)];
            if (homeSectionInfo.items.count != 0) {
                [homeSectionInfos addObject:homeSectionInfo];
            }
            else if (! self.favoriteRadioShowsLoaded) {
                [homeSectionInfos addObject:homeSectionInfo];
            }
        }
        else {
            HomeSectionInfo *homeSectionInfo = [self infoForHomeSection:homeSection.integerValue withObject:self.radioChannel.uid title:TitleForHomeSection(homeSection.integerValue)];
            [homeSectionInfos addObject:homeSectionInfo];
        }
    }
    self.homeSectionInfos = homeSectionInfos.copy;
}

- (HomeSectionInfo *)infoForHomeSection:(HomeSection)homeSection withObject:(id)object title:(NSString *)title
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == %@ AND %K == %@", @keypath(HomeSectionInfo.new, homeSection), @(homeSection),
                              @keypath(HomeSectionInfo.new, object), object];
    HomeSectionInfo *homeSectionInfo = [self.homeSectionInfos filteredArrayUsingPredicate:predicate].firstObject;
    if (!homeSectionInfo) {
        homeSectionInfo = [[HomeSectionInfo alloc] initWithHomeSection:homeSection object:object];
    }
    homeSectionInfo.title = title;
    return homeSectionInfo;
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

#pragma mark DZNEmptyDataSetSource protocol

- (NSAttributedString *)titleForEmptyDataSet:(UIScrollView *)scrollView
{
    NSError *error = self.lastRequestError;
    if (error) {
        // Multiple errors. Pick the first ones
        if ([error hasCode:SRGNetworkErrorMultiple withinDomain:SRGNetworkErrorDomain]) {
            error = [error.userInfo[SRGNetworkErrorsKey] firstObject];
        }
        return [[NSAttributedString alloc] initWithString:error.localizedDescription
                                               attributes:@{ NSFontAttributeName : [UIFont srg_mediumFontWithTextStyle:SRGAppearanceFontTextStyleTitle],
                                                             NSForegroundColorAttributeName : UIColor.play_lightGrayColor }];
    }
    else {
        return nil;
    }
}

- (NSAttributedString *)descriptionForEmptyDataSet:(UIScrollView *)scrollView
{
    if (self.lastRequestError) {
        return [[NSAttributedString alloc] initWithString:NSLocalizedString(@"Pull to reload", @"Text displayed to inform the user she can pull a list to reload it")
                                               attributes:@{ NSFontAttributeName : [UIFont srg_mediumFontWithTextStyle:SRGAppearanceFontTextStyleSubtitle],
                                                             NSForegroundColorAttributeName : UIColor.play_lightGrayColor }];
    }
    else {
        return nil;
    }
}

- (UIImage *)imageForEmptyDataSet:(UIScrollView *)scrollView
{
    if (self.lastRequestError) {
        return [UIImage imageNamed:@"error-90"];
    }
    else {
        return nil;
    }
}

- (UIColor *)imageTintColorForEmptyDataSet:(UIScrollView *)scrollView
{
    return UIColor.play_lightGrayColor;
}

- (BOOL)emptyDataSetShouldAllowScroll:(UIScrollView *)scrollView
{
    return YES;
}

- (CGFloat)verticalOffsetForEmptyDataSet:(UIScrollView *)scrollView
{
    return VerticalOffsetForEmptyDataSet(scrollView);
}

#pragma mark UITableViewDataSource protocol

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (self.loading && ! self.lastRequestError) {
        return self.homeSectionInfos.count;
    }
    else {
        NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(HomeSectionInfo * _Nullable homeSectionInfo, NSDictionary<NSString *,id> * _Nullable bindings) {
            return homeSectionInfo.items.count != 0;
        }];
        NSArray<HomeSectionInfo *> *loadedSectionInfos = [self.homeSectionInfos filteredArrayUsingPredicate:predicate];
        return (loadedSectionInfos.count != 0) ? self.homeSectionInfos.count : 0;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    HomeSectionInfo *homeSectionInfo = self.homeSectionInfos[indexPath.section];
    return [tableView dequeueReusableCellWithIdentifier:NSStringFromClass(homeSectionInfo.cellClass) forIndexPath:indexPath];
}

#pragma mark UITableViewDelegate protocol

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    HomeSectionInfo *homeSectionInfo = self.homeSectionInfos[indexPath.section];
    return [homeSectionInfo.cellClass heightForHomeSectionInfo:homeSectionInfo bounds:tableView.bounds featured:(indexPath.section == 0)];
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(HomeTableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    [cell setHomeSectionInfo:self.homeSectionInfos[indexPath.section] featured:(indexPath.section == 0)];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    HomeSectionInfo *homeSectionInfo = self.homeSectionInfos[section];
    return [HomeSectionHeaderView heightForHomeSectionInfo:homeSectionInfo bounds:tableView.bounds featured:(section == 0)];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    HomeSectionInfo *homeSectionInfo = self.homeSectionInfos[section];
    HomeSectionHeaderView *headerView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:NSStringFromClass(HomeSectionHeaderView.class)];
    [headerView setHomeSectionInfo:homeSectionInfo featured:(section == 0)];
    return headerView;
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(HomeSectionHeaderView *)headerView forSection:(NSInteger)section
{
    [headerView setHomeSectionInfo:self.homeSectionInfos[section] featured:(section == 0)];
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    // Cannot use 0 for grouped table views (will be ignored), must use a very small value instead
    return 10e-6f;
}

#pragma mark Actions

- (void)refresh:(id)sender
{
    [self refresh];
}

- (void)showNotifications:(id)sender
{
    NotificationsViewController *notificationsViewController = [[NotificationsViewController alloc] init];
    NavigationController *navigationController = [[NavigationController alloc] initWithRootViewController:notificationsViewController];
    [self presentViewController:navigationController animated:YES completion:nil];
}

- (void)search:(id)sender
{
    SearchViewController *searchViewController = [[SearchViewController alloc] initWithQuery:nil settings:nil];
    
    @weakify(self)
    searchViewController.closeBlock = ^{
        @strongify(self);
        [self dismissViewControllerAnimated:YES completion:nil];
    };
    
    NavigationController *navigationController = [[NavigationController alloc] initWithRootViewController:searchViewController];
    navigationController.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:navigationController animated:YES completion:nil];
}

#pragma mark Notifications

- (void)accessibilityVoiceOverStatusChanged:(NSNotification *)notification
{
    [self.tableView reloadData];
}

- (void)applicationDidBecomeActive:(NSNotification *)notification
{
    // Ensure correct notification button availability after:
    //   - Dismissal of the initial system alert (displayed once at most), asking the user to enable push notifications.
    //   - Returning from system settings, where the user might have updated push notification authorizations.
    [self updateBarButtonItems];
}

- (void)didReceiveNotification:(NSNotification *)notification
{
    [self updateBarButtonItems];
}

- (void)preferencesStateDidChange:(NSNotification *)notification
{
    if ([self.homeSections containsObject:@(HomeSectionTVFavoriteShows)] || [self.homeSections containsObject:@(HomeSectionRadioFavoriteShows)]) {
        NSSet<NSString *> *domains = notification.userInfo[SRGPreferencesDomainsKey];
        if ([domains containsObject:PlayPreferencesDomain]) {
            [self refresh];
        }
    }
}

@end
