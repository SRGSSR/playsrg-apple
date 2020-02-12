//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "HomeMediasViewController.h"

#import "PageViewController.h"
#import "UIColor+PlaySRG.h"
#import "UIViewController+PlaySRG.h"

@interface HomeMediasViewController ()

@property (nonatomic) HomeSectionInfo *homeSectionInfo;

@end

@implementation HomeMediasViewController

#pragma mark Object lifecycle

- (instancetype)initWithHomeSectionInfo:(HomeSectionInfo *)homeSectionInfo
{
    if (self = [super init]) {
        self.homeSectionInfo = homeSectionInfo;
        
        NSString *title = TitleForTopicSection(homeSectionInfo.topicSection) ?: homeSectionInfo.title ?: TitleForHomeSection(homeSectionInfo.homeSection);
        self.title = title;
        self.tabBarItem = [[UITabBarItem alloc] initWithTitle:title image:nil tag:0];
    }
    return self;
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-implementations"

- (instancetype)init
{
    [self doesNotRecognizeSelector:_cmd];
    return [self initWithHomeSectionInfo:[[HomeSectionInfo alloc] initWithHomeSection:HomeSectionUnknown]];
}

#pragma clang diagnostic pop

#pragma mark View lifecycle

- (void)loadView
{
    UIView *view = [[UIView alloc] initWithFrame:UIScreen.mainScreen.bounds];
    view.backgroundColor = UIColor.play_blackColor;
    
    UICollectionViewFlowLayout *collectionViewLayout = [[UICollectionViewFlowLayout alloc] init];
    UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:view.bounds collectionViewLayout:collectionViewLayout];
    collectionView.backgroundColor = UIColor.clearColor;
    collectionView.indicatorStyle = UIScrollViewIndicatorStyleWhite;
    collectionView.alwaysBounceVertical = YES;
    collectionView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [view addSubview:collectionView];
    self.collectionView = collectionView;
    
    self.view = view;
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

#pragma mark Overrides

- (void)prepareRefreshWithRequestQueue:(SRGRequestQueue *)requestQueue page:(SRGPage *)page completionHandler:(ListRequestPageCompletionHandler)completionHandler
{
    SRGBaseRequest *request = [self.homeSectionInfo requestWithPage:page completionBlock:completionHandler];
    if (request) {
        [requestQueue addRequest:request resume:YES];
    }
}

- (BOOL)srg_isTrackedAutomatically
{
    // Only tracked if presented directly without containment
    return ! self.play_pageViewController;
}

- (AnalyticsPageType)pageType
{
    switch (self.homeSectionInfo.homeSection) {
        case HomeSectionRadioLatestEpisodes:
        case HomeSectionRadioMostPopular:
        case HomeSectionRadioLatest:
        case HomeSectionRadioLatestVideos: {
            return AnalyticsPageTypeRadio;
            break;
        }
            
        default: {
            return AnalyticsPageTypeTV;
            break;
        }
    }
}

@end
