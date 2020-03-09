//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "HomeViewController.h"

#import "AnalyticsConstants.h"
#import "ApplicationConfiguration.h"
#import "ApplicationSettings.h"
#import "CalendarViewController.h"
#import "Favorites.h"
#import "GoogleCastBarButtonItem.h"
#import "Layout.h"
#import "HomeSectionHeaderView.h"
#import "HomeMediaListTableViewCell.h"
#import "HomeSectionInfo.h"
#import "HomeShowListTableViewCell.h"
#import "HomeShowsAccessTableViewCell.h"
#import "HomeShowVerticalListTableViewCell.h"
#import "HomeStatusHeaderView.h"
#import "NavigationController.h"
#import "NSBundle+PlaySRG.h"
#import "ShowsViewController.h"
#import "UIColor+PlaySRG.h"
#import "UIScrollView+PlaySRG.h"
#import "UIViewController+PlaySRG.h"

#import <CoconutKit/CoconutKit.h>
#import <libextobjc/libextobjc.h>
#import <SRGAppearance/SRGAppearance.h>
#import <SRGDataProvider/SRGDataProvider.h>
#import <SRGUserData/SRGUserData.h>

typedef NS_ENUM(NSInteger, HomeHeaderType) {
    HomeHeaderTypeNone,         // No header
    HomeHeaderTypeSpace,        // A space, no header view
    HomeHeaderTypeView          // A header with underlying view
};

@interface HomeViewController ()

@property (nonatomic) ApplicationSectionInfo *applicationSectionInfo;
@property (nonatomic) NSArray<NSNumber *> *homeSections;

@property (nonatomic) NSArray<HomeSectionInfo *> *homeSectionInfos;

@property (nonatomic) SRGServiceMessage *serviceMessage;
@property (nonatomic) NSArray<SRGTopic *> *topics;
@property (nonatomic) NSArray<SRGModule *> *eventModules;

@property (nonatomic) NSError *lastRequestError;

@property (nonatomic, weak) UIRefreshControl *refreshControl;
@property (nonatomic, weak) IBOutlet UITableView *tableView;

@property (nonatomic, getter=isTopicsLoaded) BOOL topicsLoaded;
@property (nonatomic, getter=isEventsLoaded) BOOL eventsLoaded;
@end

@implementation HomeViewController

#pragma mark Object lifecycle

- (instancetype)initWithApplicationSectionInfo:(ApplicationSectionInfo *)applicationSectionInfo homeSections:(NSArray<NSNumber *> *)homeSections
{
    if (self = [super init]) {
        self.applicationSectionInfo = applicationSectionInfo;
        self.homeSections = homeSections;
        self.title = applicationSectionInfo.title;
        
        [self synchronizeHomeSections];
    }
    return self;
}

#pragma mark Getters and setters

- (RadioChannel *)radioChannel
{
    return self.applicationSectionInfo.radioChannel;
}

#pragma mark View lifecycle

- (void)loadView
{
    UIView *view = [[UIView alloc] initWithFrame:UIScreen.mainScreen.bounds];
    view.backgroundColor = UIColor.play_blackColor;
        
    UITableView *tableView = [[UITableView alloc] initWithFrame:view.bounds style:UITableViewStyleGrouped];
    tableView.backgroundColor = UIColor.clearColor;
    tableView.indicatorStyle = UIScrollViewIndicatorStyleWhite;
    tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [view addSubview:tableView];
    self.tableView = tableView;
    
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    refreshControl.tintColor = UIColor.whiteColor;
    [refreshControl addTarget:self action:@selector(refresh:) forControlEvents:UIControlEventValueChanged];
    [tableView insertSubview:refreshControl atIndex:0];
    self.refreshControl = refreshControl;
    
    self.view = view;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    
    self.tableView.emptyDataSetSource = self;
    self.tableView.emptyDataSetDelegate = self;
    
    Class mediaListCellClass = HomeMediaListTableViewCell.class;
    [self.tableView registerClass:mediaListCellClass forCellReuseIdentifier:NSStringFromClass(mediaListCellClass)];
    
    Class showListCellClass = HomeShowListTableViewCell.class;
    [self.tableView registerClass:showListCellClass forCellReuseIdentifier:NSStringFromClass(showListCellClass)];
    
    Class showVerticallListCellClass = HomeShowVerticalListTableViewCell.class;
    [self.tableView registerClass:showVerticallListCellClass forCellReuseIdentifier:NSStringFromClass(showVerticallListCellClass)];
    
    NSString *showsAccessCellIdentifier = NSStringFromClass(HomeShowsAccessTableViewCell.class);
    UINib *homeShowsAccessTableViewCellNib = [UINib nibWithNibName:showsAccessCellIdentifier bundle:nil];
    [self.tableView registerNib:homeShowsAccessTableViewCellNib forCellReuseIdentifier:showsAccessCellIdentifier];
    
    NSString *headerIdentifier = NSStringFromClass(HomeSectionHeaderView.class);
    UINib *homeSectionHeaderViewNib = [UINib nibWithNibName:headerIdentifier bundle:nil];
    [self.tableView registerNib:homeSectionHeaderViewNib forHeaderFooterViewReuseIdentifier:headerIdentifier];
    
    UINavigationBar *navigationBar = self.navigationController.navigationBar;
    if (navigationBar) {
        self.navigationItem.rightBarButtonItem = [[GoogleCastBarButtonItem alloc] initForNavigationBar:navigationBar];
    }
    
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(accessibilityVoiceOverStatusChanged:)
                                               name:UIAccessibilityVoiceOverStatusChanged
                                             object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(preferencesStateDidChange:)
                                               name:SRGPreferencesDidChangeNotification
                                             object:SRGUserData.currentUserData.preferences];
    
    [self updateStatusHeaderViewLayout];
    [self.tableView reloadData];
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

#pragma mark Section management

- (void)refreshHomeSection:(HomeSection)homeSection withRequestQueue:(SRGRequestQueue *)requestQueue
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == %@", @keypath(HomeSectionInfo.new, homeSection), @(homeSection)];
    NSArray<HomeSectionInfo *> *homeSectionInfos = [self.homeSectionInfos filteredArrayUsingPredicate:predicate];
    for (HomeSectionInfo *homeSectionInfo in homeSectionInfos) {
        [homeSectionInfo refreshWithRequestQueue:requestQueue page:nil /* only the first page */ completionBlock:^(NSArray * _Nullable items, SRGPage * _Nonnull page, SRGPage * _Nullable nextPage, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
            // Refresh as data becomes available for better perceived loading times
            if (! error) {
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
            [homeSectionInfos addObject:homeSectionInfo];
        }
        else if (homeSection.integerValue == HomeSectionRadioFavoriteShows) {
            HomeSectionInfo *homeSectionInfo = [self infoForHomeSection:homeSection.integerValue withObject:self.radioChannel.uid title:TitleForHomeSection(homeSection.integerValue)];
            [homeSectionInfos addObject:homeSectionInfo];
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
    if (! homeSectionInfo) {
        homeSectionInfo = [[HomeSectionInfo alloc] initWithHomeSection:homeSection object:object];
    }
    homeSectionInfo.title = title;
    return homeSectionInfo;
}

- (BOOL)isFeaturedInSection:(NSUInteger)section
{
    if (self.applicationSectionInfo.applicationSection == ApplicationSectionLive) {
        return YES;
    }
    else {
        return section == 0;
    }
}

- (HomeHeaderType)headerTypeForHomeSectionInfo:(HomeSectionInfo *)homeSectionInfo tableView:(UITableView *)tableView inSection:(NSUInteger)section
{
    if (self.applicationSectionInfo.applicationSection == ApplicationSectionLive) {
        return HomeHeaderTypeView;
    }
    else {
        if (section == 0) {
            ApplicationConfiguration *applicationConfiguration = ApplicationConfiguration.sharedApplicationConfiguration;
            BOOL isRadioChannel = ([applicationConfiguration radioChannelForUid:homeSectionInfo.identifier] != nil);
            BOOL isFeaturedHeaderHidden = isRadioChannel ? applicationConfiguration.radioFeaturedHomeSectionHeaderHidden : applicationConfiguration.tvFeaturedHomeSectionHeaderHidden;
            if (! UIAccessibilityIsVoiceOverRunning() && isFeaturedHeaderHidden) {
                return HomeHeaderTypeSpace;
            }
            else {
                return HomeHeaderTypeView;
            }
        }
        else {
            return HomeHeaderTypeView;
        }
    }
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

#pragma mark PlayApplicationNavigation protocol

- (BOOL)openApplicationSectionInfo:(ApplicationSectionInfo *)applicationSectionInfo
{
    BOOL sameChannel = (self.radioChannel == applicationSectionInfo.radioChannel) || [self.radioChannel isEqual:applicationSectionInfo.radioChannel];
    if (! sameChannel) {
        return NO;
    }
    
    if (applicationSectionInfo.applicationSection == ApplicationSectionShowByDate) {
        NSDate *date = applicationSectionInfo.options[ApplicationSectionOptionShowByDateDateKey];
        CalendarViewController *calendarViewController = [[CalendarViewController alloc] initWithRadioChannel:applicationSectionInfo.radioChannel date:date];
        [self.navigationController pushViewController:calendarViewController animated:NO];
        return YES;
    }
    else if (applicationSectionInfo.applicationSection == ApplicationSectionShowAZ) {
        NSString *index = applicationSectionInfo.options[ApplicationSectionOptionShowAZIndexKey];
        ShowsViewController *showsViewController = [[ShowsViewController alloc] initWithRadioChannel:applicationSectionInfo.radioChannel alphabeticalIndex:index];
        [self.navigationController pushViewController:showsViewController animated:NO];
        return YES;
    }
    else {
        return applicationSectionInfo.applicationSection == ApplicationSectionOverview;
    }
}

#pragma mark Scrollable protocol

- (void)scrollToTopAnimated:(BOOL)animated
{
    [self.tableView play_scrollToTopAnimated:animated];
}

#pragma mark SRGAnalyticsViewTracking protocol

- (NSString *)srg_pageViewTitle
{
    return AnalyticsPageTitleHome;
}

- (NSArray<NSString *> *)srg_pageViewLevels
{
    if (self.radioChannel) {
        return @[ AnalyticsPageLevelPlay, AnalyticsPageLevelAudio, self.radioChannel.name ];
    }
    else if (self.applicationSectionInfo.applicationSection == ApplicationSectionLive) {
        return @[ AnalyticsPageLevelPlay, AnalyticsPageLevelLive ];
    }
    else {
        return @[ AnalyticsPageLevelPlay, AnalyticsPageLevelVideo ];
    }
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
    if (! homeSectionInfo.hidden) {
        BOOL featured = [self isFeaturedInSection:indexPath.section];
        return [homeSectionInfo.cellClass heightForHomeSectionInfo:homeSectionInfo bounds:tableView.bounds featured:featured];
    }
    else {
        return 0.f;
    }
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(HomeTableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    BOOL featured = [self isFeaturedInSection:indexPath.section];
    [cell setHomeSectionInfo:self.homeSectionInfos[indexPath.section] featured:featured];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    HomeSectionInfo *homeSectionInfo = self.homeSectionInfos[section];
    if (homeSectionInfo.hidden) {
        return 0.f;
    }
    
    HomeHeaderType headerType = [self headerTypeForHomeSectionInfo:homeSectionInfo tableView:tableView inSection:section];
    switch (headerType) {
        case HomeHeaderTypeSpace: {
            return LayoutStandardMargin;
            break;
        }
            
        case HomeHeaderTypeView: {
            return LayoutStandardTableSectionHeaderHeight();
            break;
        }
        
        default: {
            return 0.f;
            break;
        }
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    HomeSectionInfo *homeSectionInfo = self.homeSectionInfos[section];
    if (homeSectionInfo.hidden) {
        return nil;
    }
    
    HomeHeaderType headerType = [self headerTypeForHomeSectionInfo:homeSectionInfo tableView:tableView inSection:section];
    if (headerType == HomeHeaderTypeView) {
        HomeSectionHeaderView *headerView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:NSStringFromClass(HomeSectionHeaderView.class)];
        headerView.homeSectionInfo = homeSectionInfo;
        return headerView;
    }
    else {
        return nil;
    }
}

#pragma mark Actions

- (void)refresh:(id)sender
{
    [self refresh];
}

#pragma mark Notifications

- (void)accessibilityVoiceOverStatusChanged:(NSNotification *)notification
{
    [self.tableView reloadData];
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
