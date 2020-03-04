//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "HomeMediasViewController.h"

#import "AnalyticsConstants.h"
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
        
        NSString *title = nil;
        if ([homeSectionInfo.topic isKindOfClass:SRGSubtopic.class]) {
            title = homeSectionInfo.title;
        }
        else {
            title = TitleForTopicSection(homeSectionInfo.topicSection) ?: TitleForHomeSection(homeSectionInfo.homeSection);
        }
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

#pragma mark SRGAnalyticsViewTracking protocol

- (NSString *)srg_pageViewTitle
{
    SRGBaseTopic *topic = self.homeSectionInfo.topic;
    if (topic) {
        if ([topic isKindOfClass:SRGSubtopic.class]) {
            return topic.title;
        }
        else {
            return AnalyticsPageTitleForTopicSection(self.homeSectionInfo.topicSection);
        }
    }
    else {
        return AnalyticsPageTitleForHomeSection(self.homeSectionInfo.homeSection);
    }
}

- (NSArray<NSString *> *)srg_pageViewLevels
{
    SRGBaseTopic *topic = self.homeSectionInfo.topic;
    if (topic) {
        NSString *level2 = (topic.transmission == SRGTransmissionRadio) ? AnalyticsPageLevelAudio : AnalyticsPageLevelVideo;
        
        if ([topic isKindOfClass:SRGSubtopic.class]) {
            NSString *parentTitle = self.homeSectionInfo.parentTitle;
            NSAssert(parentTitle != nil, @"Parent information must have been filled for subtopics");
            return @[ AnalyticsPageLevelPlay, level2, parentTitle ];
        }
        else {
            return @[ AnalyticsPageLevelPlay, level2, topic.title ];
        }
    }
    else {
        ApplicationConfiguration *applicationConfiguration = ApplicationConfiguration.sharedApplicationConfiguration;
        RadioChannel *radioChannel = [applicationConfiguration radioChannelForUid:self.homeSectionInfo.identifier];
        if (radioChannel) {
            NSString *level2 = (self.homeSectionInfo.homeSection == HomeSectionRadioLatestVideos) ? AnalyticsPageLevelVideo : AnalyticsPageLevelAudio;
            return @[ AnalyticsPageLevelPlay, level2, radioChannel.name ];
        }
        else if (self.homeSectionInfo.homeSection == HomeSectionTVLive || self.homeSectionInfo.homeSection == HomeSectionRadioLive
                    || self.homeSectionInfo.homeSection == HomeSectionTVLiveCenter || self.homeSectionInfo.homeSection == HomeSectionTVScheduledLivestreams) {
            return @[ AnalyticsPageLevelPlay, AnalyticsPageLevelLive ];
        }
        else {
            return @[ AnalyticsPageLevelPlay, AnalyticsPageLevelVideo ];
        }
    }
}

@end
