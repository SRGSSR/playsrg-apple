//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "HomeLivestreamsViewController.h"

#import "AnalyticsConstants.h"
#import "ApplicationSettings.h"
#import "ChannelService.h"
#import "LiveMediaCollectionViewCell.h"
#import "PageViewController.h"
#import "UIColor+PlaySRG.h"
#import "UIViewController+PlaySRG.h"

#import <libextobjc/libextobjc.h>
#import <SRGAppearance/SRGAppearance.h>

static const CGFloat kLayoutHorizontalInset = 10.f;

@interface HomeLivestreamsViewController ()

@property (nonatomic) HomeSectionInfo *homeSectionInfo;

@property (nonatomic) NSMutableArray<SRGMedia *> *pendingMedias;
@property (nonatomic) ListRequestPageCompletionHandler completionHandler;

@end

@implementation HomeLivestreamsViewController

#pragma mark Object lifecycle

- (instancetype)initWithHomeSectionInfo:(HomeSectionInfo *)homeSectionInfo
{
    if (self = [super init]) {
        self.homeSectionInfo = homeSectionInfo;
        
        NSString *title = TitleForHomeSection(homeSectionInfo.homeSection);
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
    collectionViewLayout.minimumLineSpacing = 20.f;
    
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
    
    self.emptyCollectionImage = [UIImage imageNamed:@"media-90"];
    
    NSString *liveCellIdentifier = NSStringFromClass(LiveMediaCollectionViewCell.class);
    UINib *liveCellNib = [UINib nibWithNibName:liveCellIdentifier bundle:nil];
    [self.collectionView registerNib:liveCellNib forCellWithReuseIdentifier:liveCellIdentifier];
    
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(channelServiceDidUpdateChannels:)
                                               name:ChannelServiceDidUpdateChannelsNotification
                                             object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(accessibilityVoiceOverStatusChanged:)
                                               name:UIAccessibilityVoiceOverStatusChanged
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

#pragma mark Overrides

- (void)prepareRefreshWithRequestQueue:(SRGRequestQueue *)requestQueue page:(SRGPage *)page completionHandler:(ListRequestPageCompletionHandler)completionHandler
{
    SRGBaseRequest *request = [self.homeSectionInfo requestWithPage:page completionBlock:^(NSArray * _Nullable items, SRGPage * _Nonnull page, SRGPage * _Nullable nextPage, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
        // Support radio regional live streams
        if (self.homeSectionInfo.homeSection == HomeSectionRadioLive) {
            NSArray<SRGMedia *> *originalMedias = items;
            NSMutableArray<SRGMedia *> *medias = items.mutableCopy;
            
            self.completionHandler = completionHandler;
            self.pendingMedias = NSMutableArray.array;
            
            void (^replaceCompletion)(NSArray * _Nullable, SRGPage * _Nonnull, SRGPage * _Nullable, NSHTTPURLResponse * _Nullable, NSError * _Nullable) = ^(NSArray *items, SRGPage *page, SRGPage *nextPage, NSHTTPURLResponse *HTTPResponse, NSError *error) {
                if (self.pendingMedias.count == 0) {
                    self.completionHandler(items, page, nextPage, HTTPResponse, error);
                    self.completionHandler = nil;
                    self.pendingMedias = nil;
                }
            };
            
            for (SRGMedia *originalMedia in originalMedias) {
                NSString *selectedLiveStreamURN = ApplicationSettingSelectedLiveStreamURNForChannelUid(originalMedia.channel.uid);
                
                // If a regional stream has been selected by the user, replace the main channel media with it
                if (selectedLiveStreamURN && ! [originalMedia.URN isEqual:selectedLiveStreamURN]) {
                    [self.pendingMedias addObject:originalMedia];
                    
                    SRGRequest *request = [SRGDataProvider.currentDataProvider radioLivestreamsForVendor:ApplicationConfiguration.sharedApplicationConfiguration.vendor channelUid:originalMedia.channel.uid withCompletionBlock:^(NSArray<SRGMedia *> * _Nullable channelMedias, NSHTTPURLResponse * _Nullable channelMediasHTTPResponse, NSError * _Nullable channelMediasError) {
                        [requestQueue reportError:channelMediasError];
                        
                        SRGMedia *selectedMedia = ApplicationSettingSelectedLivestreamMediaForChannelUid(originalMedia.channel.uid, channelMedias);
                        if (selectedMedia) {
                            NSInteger index = [medias indexOfObject:originalMedia];
                            NSAssert(index != NSNotFound, @"Media must be found in array by construction");
                            [medias replaceObjectAtIndex:index withObject:selectedMedia];
                        }
                        
                        [self.pendingMedias removeObject:originalMedia];
                        replaceCompletion(medias.copy, page, nextPage, HTTPResponse, error);
                    }];
                    [requestQueue addRequest:request resume:YES];
                }
            }
            replaceCompletion(medias.copy, page, nextPage, HTTPResponse, error);
        }
        else {
            completionHandler(items, page, nextPage, HTTPResponse, error);
        }
    }];
    if (request) {
        [requestQueue addRequest:request resume:YES];
    }
}

#pragma mark SRGAnalyticsViewTracking protocol

- (NSString *)srg_pageViewTitle
{
    return AnalyticsPageTitleForHomeSection(self.homeSectionInfo.homeSection);
}

- (NSArray<NSString *> *)srg_pageViewLevels
{
    return @[ AnalyticsPageLevelPlay, AnalyticsPageLevelLive ];
}

#pragma mark UICollectionViewDataSource protocol

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.items.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass(LiveMediaCollectionViewCell.class.class)
                                                     forIndexPath:indexPath];
}

#pragma mark UICollectionViewDelegate protocol

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(LiveMediaCollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    [cell setMedia:self.items[indexPath.row]];
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    SRGMedia *media = self.items[indexPath.row];
    [self play_presentMediaPlayerWithMedia:media position:nil airPlaySuggestions:YES fromPushNotification:NO animated:YES completion:nil];
}

#pragma mark UICollectionViewDelegateFlowLayout protocol

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    return UIEdgeInsetsMake(10.f, kLayoutHorizontalInset, 10.f, kLayoutHorizontalInset);
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewFlowLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *contentSizeCategory = UIApplication.sharedApplication.preferredContentSizeCategory;
    
    // Large cell table layout
    if (self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassCompact) {
        SRGMedia *media = self.items[indexPath.row];
        CGFloat width = CGRectGetWidth(collectionView.frame) - 2 * kLayoutHorizontalInset;
        CGFloat height = [LiveMediaCollectionViewCell heightForMedia:media withWidth:width];
        return CGSizeMake(width, height);
    }
    // 2 columns grid layout
    else {
        CGFloat minTextHeight = (SRGAppearanceCompareContentSizeCategories(contentSizeCategory, UIContentSizeCategoryExtraLarge) == NSOrderedAscending) ? 90.f : 120.f;
        
        CGFloat width = (CGRectGetWidth(collectionView.frame) - 3 * kLayoutHorizontalInset) / 2.f;
        return CGSizeMake(width, ceilf(width * 9.f / 16.f + minTextHeight));
    }
}

#pragma mark Notifications

- (void)channelServiceDidUpdateChannels:(NSNotification *)notification
{
    [self.collectionView.collectionViewLayout invalidateLayout];
}

- (void)accessibilityVoiceOverStatusChanged:(NSNotification *)notification
{
    [self.collectionView reloadData];
}

@end
