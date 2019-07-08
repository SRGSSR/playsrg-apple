//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SearchSettingsViewController.h"

#import "AnalyticsConstants.h"
#import "ApplicationConfiguration.h"
#import "SearchSettingsHeaderView.h"
#import "SearchSettingSelectorCell.h"
#import "SearchSettingSegmentCell.h"
#import "SearchSettingSwitchCell.h"
#import "UIColor+PlaySRG.h"
#import "UIViewController+PlaySRG.h"

#import <libextobjc/libextobjc.h>

@interface SearchSettingsViewController ()

@property (nonatomic, copy) NSString *query;
@property (nonatomic) SRGMediaSearchSettings *settings;

@property (nonatomic) SRGMediaAggregations *aggregations;

@property (nonatomic, weak) IBOutlet UITableView *tableView;

@end

@implementation SearchSettingsViewController

#pragma mark Object lifecycle

- (instancetype)initWithQuery:(NSString *)query settings:(SRGMediaSearchSettings *)settings
{
    if (self = [super init]) {
        self.query = query;
        self.settings = [settings copy] ?: [[SRGMediaSearchSettings alloc] init];
        self.settings.aggregationsEnabled = YES;
    }
    return self;
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-implementations"

- (instancetype)init
{
    [self doesNotRecognizeSelector:_cmd];
    return [self initWithQuery:nil settings:SRGMediaSearchSettings.new];
}

#pragma clang diagnostic pop

#pragma mark Getters and setters

- (NSString *)title
{
    return NSLocalizedString(@"Search filters", @"Search filters page title");
}

#pragma mark View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = UIColor.play_popoverGrayColor;
    
    self.tableView.backgroundView = nil;
    self.tableView.backgroundColor = UIColor.clearColor;
    self.tableView.separatorColor = UIColor.clearColor;
    self.tableView.estimatedRowHeight = 44.f;
    self.tableView.indicatorStyle = UIScrollViewIndicatorStyleWhite;
    
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    
    NSString *headerIdentifier = NSStringFromClass(SearchSettingsHeaderView.class);
    UINib *headerViewNib = [UINib nibWithNibName:headerIdentifier bundle:nil];
    [self.tableView registerNib:headerViewNib forHeaderFooterViewReuseIdentifier:headerIdentifier];
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

#pragma mark Overrides

- (void)prepareRefreshWithRequestQueue:(SRGRequestQueue *)requestQueue
{
    ApplicationConfiguration *applicationConfiguration = ApplicationConfiguration.sharedApplicationConfiguration;
    SRGBaseRequest *request = [SRGDataProvider.currentDataProvider mediasForVendor:applicationConfiguration.vendor matchingQuery:self.query withSettings:self.settings completionBlock:^(NSArray<NSString *> * _Nullable mediaURNs, NSNumber * _Nonnull total, SRGMediaAggregations * _Nullable aggregations, NSArray<SRGSearchSuggestion *> * _Nullable suggestions, SRGPage * _Nonnull page, SRGPage * _Nullable nextPage, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
        self.aggregations = aggregations;
        [self.tableView reloadData];
    }];
    [requestQueue addRequest:request resume:YES];
}

- (void)refreshDidStart
{}

- (void)refreshDidFinishWithError:(NSError *)error
{}

#pragma mark UI

- (NSString *)titleForSection:(NSInteger)section
{
    static dispatch_once_t s_onceToken;
    static NSDictionary<NSNumber *, NSString *> *s_titles;
    dispatch_once(&s_onceToken, ^{
        s_titles = @{ @1 : NSLocalizedString(@"Period", @"Settings section header"),
                      @2 : NSLocalizedString(@"Duration", @"Settings section header"),
                      @3 : NSLocalizedString(@"Properties", @"Settings section header") };
    });
    return s_titles[@(section)];
}

#pragma mark Updates

- (void)updateResults
{
    [self.delegate searchSettingsViewController:self didUpdateSettings:self.settings];
    [self refresh];
}

#pragma mark SRGAnalyticsViewTracking protocol

- (NSString *)srg_pageViewTitle
{
    return self.title;
}

- (NSArray<NSString *> *)srg_pageViewLevels
{
    return @[ AnalyticsNameForPageType(AnalyticsPageTypeSearch) ];
}

#pragma mark UITableViewDataSource protocol

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 4;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    static dispatch_once_t s_onceToken;
    static NSDictionary<NSNumber *, NSNumber *> *s_rows;
    dispatch_once(&s_onceToken, ^{
        s_rows = @{ @0 : @2,
                    @1 : @4,
                    @2 : @1,
                    @3 : @2 };
    });
    
    return s_rows[@(section)].integerValue;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static dispatch_once_t s_onceToken;
    static NSDictionary<NSNumber *, NSDictionary<NSNumber *, Class> *> *s_cellClasses;
    dispatch_once(&s_onceToken, ^{
        s_cellClasses = @{ @0 : @{ @0 : SearchSettingSelectorCell.class,
                                   @1 : SearchSettingSelectorCell.class },
                           @1 : @{ @0 : SearchSettingSelectorCell.class,
                                   @1 : SearchSettingSelectorCell.class,
                                   @2 : SearchSettingSelectorCell.class,
                                   @3 : SearchSettingSelectorCell.class },
                           @2 : @{ @0 : SearchSettingSegmentCell.class },
                           @3 : @{ @0 : SearchSettingSwitchCell.class,
                                   @1 : SearchSettingSwitchCell.class } };
    });
    Class cellClass = s_cellClasses[@(indexPath.section)][@(indexPath.row)];
    return [tableView dequeueReusableCellWithIdentifier:NSStringFromClass(cellClass) forIndexPath:indexPath];
}

#pragma mark UITableViewDelegate protocol

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    SRGMediaSearchSettings *settings = self.settings;
    
    switch (indexPath.section) {
        case 0: {
            
            break;
        }
            
        case 1: {
            SearchSettingSelectorCell *selectorCell = (SearchSettingSelectorCell *)cell;
            
            switch (indexPath.row) {
                case 0: {
                    selectorCell.name = NSLocalizedString(@"The last 24 hours", @"Period setting option");
                    break;
                }
                    
                case 1: {
                    selectorCell.name = NSLocalizedString(@"The last 3 days", @"Period setting option");
                    break;
                }
                    
                case 2: {
                    selectorCell.name = NSLocalizedString(@"The last week", @"Period setting option");
                    break;
                }
                    
                case 3: {
                    selectorCell.name = NSLocalizedString(@"The last month", @"Period setting option");
                    break;
                }
                    
                default: {
                    break;
                }
            }
            break;
        }
            
        case 2: {
            switch (indexPath.row) {
                case 0: {
                    SearchSettingSegmentCell *segmentCell = (SearchSettingSegmentCell *)cell;
                    
                    @weakify(self)
                    [segmentCell setItems:@[ NSLocalizedString(@"All", @"All option"), NSLocalizedString(@"< 5 min", @"Less than 5 min option"), NSLocalizedString(@"> 30 min", @"More than 3 min option") ] reader:^NSInteger{
                        if (! settings.minimumDurationInMinutes && ! settings.maximumDurationInMinutes) {
                            return 0;
                        }
                        else if (settings.maximumDurationInMinutes) {
                            return 1;
                        }
                        else {
                            return 2;
                        }
                    } writer:^(NSInteger index) {
                        @strongify(self)
                        
                        switch (index) {
                            case 0: {
                                settings.minimumDurationInMinutes = nil;
                                settings.maximumDurationInMinutes = nil;
                                break;
                            }
                                
                            case 1: {
                                settings.minimumDurationInMinutes = nil;
                                settings.maximumDurationInMinutes = @5;
                                break;
                            }
                                
                            case 2: {
                                settings.minimumDurationInMinutes = @30;
                                settings.maximumDurationInMinutes = nil;
                                break;
                            }
                                
                            default: {
                                break;
                            }
                        }
                        [self updateResults];
                    }];
                    break;
                }
                    
                default: {
                    break;
                }
            }
            break;
        }
            
        case 3: {
            switch (indexPath.row) {
                case 0: {
                    SearchSettingSwitchCell *switchCell = (SearchSettingSwitchCell *)cell;
                    
                    @weakify(self)
                    [switchCell setName:NSLocalizedString(@"Available for download", @"Download availability toggle name in search settings") reader:^BOOL{
                        return settings.downloadAvailable.boolValue;
                    } writer:^(BOOL value) {
                        @strongify(self)
                        
                        settings.downloadAvailable = @(value);
                        [self updateResults];
                    }];
                    break;
                }
                    
                case 1: {
                    SearchSettingSwitchCell *switchCell = (SearchSettingSwitchCell *)cell;
                    
                    @weakify(self)
                    [switchCell setName:NSLocalizedString(@"Playable abroad", @"Abroad playability toggle name in search settings") reader:^BOOL{
                        return settings.playableAbroad.boolValue;
                    } writer:^(BOOL value) {
                        @strongify(self)
                        
                        settings.playableAbroad = @(value);
                        [self updateResults];
                    }];
                    break;
                }
                    
                default: {
                    break;
                }
            }
            break;
        }
            
        default: {
            break;
        }
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    NSString *title = [self titleForSection:section];
    return title.length != 0 ? 60.f : 0.f;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    SearchSettingsHeaderView *headerView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:NSStringFromClass(SearchSettingsHeaderView.class)];
    headerView.title = [self titleForSection:section];
    return headerView;
}

@end
