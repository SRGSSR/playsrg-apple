//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SearchSettingsViewController.h"

#import "AnalyticsConstants.h"
#import "ApplicationConfiguration.h"
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
    self.tableView.estimatedRowHeight = 44.f;
    
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
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
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    static dispatch_once_t s_onceToken;
    static NSDictionary<NSNumber *, NSNumber *> *s_rows;
    dispatch_once(&s_onceToken, ^{
        s_rows = @{ @0 : @2,
                    @1 : @1,
                    @2 : @2 };
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
                           @1 : @{ @0 : SearchSettingSegmentCell.class },
                           @2 : @{ @0 : SearchSettingSwitchCell.class,
                                   @1 : SearchSettingSwitchCell.class } };
    });
    Class cellClass = s_cellClasses[@(indexPath.section)][@(indexPath.row)];
    return [tableView dequeueReusableCellWithIdentifier:NSStringFromClass(cellClass) forIndexPath:indexPath];
}

#pragma mark UITableViewDelegate protocol

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section) {
        case 0: {
            
            break;
        }
            
        case 1: {
            switch (indexPath.row) {
                case 0: {
                    SearchSettingSegmentCell *segmentCell = (SearchSettingSegmentCell *)cell;
                    [segmentCell setName:NSLocalizedString(@"Duration", @"Duration setting name in search settings") items:@[ NSLocalizedString(@"All", @"All option"), NSLocalizedString(@"< 5 min", @"Less than 5 min option"), NSLocalizedString(@"> 30 min", @"More than 3 min option") ] reader:^NSInteger{
                        if (! self.settings.minimumDurationInMinutes && ! self.settings.maximumDurationInMinutes) {
                            return 0;
                        }
                        else if (self.settings.maximumDurationInMinutes) {
                            return 1;
                        }
                        else {
                            return 2;
                        }
                    } writer:^(NSInteger index) {
                        switch (index) {
                            case 0: {
                                self.settings.minimumDurationInMinutes = nil;
                                self.settings.maximumDurationInMinutes = nil;
                                break;
                            }
                                
                            case 1: {
                                self.settings.minimumDurationInMinutes = nil;
                                self.settings.maximumDurationInMinutes = @(5);
                                break;
                            }
                                
                            case 2: {
                                self.settings.minimumDurationInMinutes = @(30);
                                self.settings.maximumDurationInMinutes = nil;
                                break;
                            }
                                
                            default: {
                                break;
                            }
                        }
                    }];
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
                    SearchSettingSwitchCell *switchCell = (SearchSettingSwitchCell *)cell;
                    [switchCell setName:NSLocalizedString(@"Available for download", @"Download availability toggle name in search settings") reader:^BOOL{
                        return self.settings.downloadAvailable;
                    } writer:^(BOOL value) {
                        self.settings.downloadAvailable = @(value);
                    }];
                    break;
                }
                    
                case 1: {
                    SearchSettingSwitchCell *switchCell = (SearchSettingSwitchCell *)cell;
                    [switchCell setName:NSLocalizedString(@"Playable abroad", @"Abroad playability toggle name in search settings") reader:^BOOL{
                        return self.settings.playableAbroad;
                    } writer:^(BOOL value) {
                        self.settings.playableAbroad = @(value);
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

@end
