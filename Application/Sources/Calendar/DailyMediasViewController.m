//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "DailyMediasViewController.h"

#import "ApplicationConfiguration.h"
#import "Layout.h"
#import "NSDateFormatter+PlaySRG.h"
#import "UIColor+PlaySRG.h"
#import "UIDevice+PlaySRG.h"
#import "UIViewController+PlaySRG.h"

@import SRGDataProviderNetwork;

@interface DailyMediasViewController ()

@property (nonatomic) NSDate *date;

@property (nonatomic) RadioChannel *radioChannel;

@end

@implementation DailyMediasViewController

#pragma mark Object lifecycle

- (instancetype)initWithDate:(NSDate *)date radioChannel:(RadioChannel *)radioChannel
{
    if (self = [super init]) {
        self.date = date;
        self.radioChannel = radioChannel;
        self.dateFormatter = NSDateFormatter.play_shortTimeFormatter;
    }
    return self;
}

#pragma mark View lifecycle

- (void)loadView
{
    UIView *view = [[UIView alloc] initWithFrame:UIScreen.mainScreen.bounds];
    view.backgroundColor = UIColor.play_blackColor;
    
    UICollectionViewFlowLayout *collectionViewLayout = [[UICollectionViewFlowLayout alloc] init];
    collectionViewLayout.scrollDirection = UICollectionViewScrollDirectionVertical;
    
    UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:view.bounds collectionViewLayout:collectionViewLayout];
    collectionView.backgroundColor = UIColor.clearColor;
    collectionView.indicatorStyle = UIScrollViewIndicatorStyleWhite;
    collectionView.alwaysBounceVertical = YES;
    collectionView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [view addSubview:collectionView];
    self.collectionView = collectionView;
    
    self.view = view;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self updateAppearanceForSize:self.view.frame.size];
    
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(accessibilityVoiceOverStatusChanged:)
                                               name:UIAccessibilityVoiceOverStatusDidChangeNotification
                                             object:nil];
}

#pragma mark Rotation

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return [super supportedInterfaceOrientations] & UIViewController.play_supportedInterfaceOrientations;
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> _Nonnull context) {
        [self updateAppearanceForSize:size];
    } completion:nil];
}

#pragma mark Status bar

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

#pragma mark Overrides

- (void)prepareRefreshWithRequestQueue:(SRGRequestQueue *)requestQueue page:(SRGPage *)page completionHandler:(ListRequestPageCompletionHandler)completionHandler
{
    ApplicationConfiguration *applicationConfiguration = ApplicationConfiguration.sharedApplicationConfiguration;
    
    SRGDay *day = [SRGDay dayFromDate:self.date];
    if (self.radioChannel) {
        SRGPageRequest *request = [[[SRGDataProvider.currentDataProvider radioEpisodesForVendor:applicationConfiguration.vendor channelUid:self.radioChannel.uid day:day withCompletionBlock:completionHandler] requestWithPageSize:applicationConfiguration.pageSize] requestWithPage:page];
        [requestQueue addRequest:request resume:YES];
    }
    else {
        SRGPageRequest *request = [[[SRGDataProvider.currentDataProvider tvEpisodesForVendor:applicationConfiguration.vendor day:day withCompletionBlock:completionHandler] requestWithPageSize:applicationConfiguration.pageSize] requestWithPage:page];
        [requestQueue addRequest:request resume:YES];
    }
}

#pragma mark UI

- (void)updateAppearanceForSize:(CGSize)size
{
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone && size.width > size.height) {
        self.emptyCollectionImage = nil;
    }
    else {
        self.emptyCollectionImage = [UIImage imageNamed:@"media-90"];
    }
    
    [self.collectionView reloadEmptyDataSet];
}

#pragma mark Notifications

- (void)accessibilityVoiceOverStatusChanged:(NSNotification *)notification
{
    [self.collectionView reloadData];
}

@end
