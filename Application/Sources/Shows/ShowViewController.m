//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "ShowViewController.h"

#import "AnalyticsConstants.h"
#import "ApplicationConfiguration.h"
#import "Banner.h"
#import "Favorites.h"
#import "Layout.h"
#import "NSBundle+PlaySRG.h"
#import "PlayAppDelegate.h"
#import "SharingItem.h"
#import "ShowHeaderView.h"
#import "UIApplication+PlaySRG.h"
#import "UIColor+PlaySRG.h"
#import "UIView+PlaySRG.h"
#import "UIViewController+PlaySRG.h"

@import Intents;
@import libextobjc;
@import SRGAppearance;

@interface ShowViewController ()

@property (nonatomic) SRGShow *show;

@property (nonatomic, getter=isFromPushNotification) BOOL fromPushNotification;

@end

@implementation ShowViewController

#pragma mark Object lifecycle

- (instancetype)initWithShow:(SRGShow *)show fromPushNotification:(BOOL)fromPushNotification
{
    if (self = [super init]) {
        self.show = show;
        self.fromPushNotification = fromPushNotification;
    }
    return self;
}

#pragma mark View lifecycle

- (void)loadView
{
    UIView *view = [[UIView alloc] initWithFrame:UIScreen.mainScreen.bounds];
    view.backgroundColor = UIColor.srg_gray1Color;
    
    UICollectionViewFlowLayout *collectionViewLayout = [[UICollectionViewFlowLayout alloc] init];
    collectionViewLayout.scrollDirection = UICollectionViewScrollDirectionVertical;
    
    UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:view.bounds collectionViewLayout:collectionViewLayout];
    collectionView.backgroundColor = UIColor.clearColor;
    collectionView.indicatorStyle = UIScrollViewIndicatorStyleWhite;
    collectionView.alwaysBounceVertical = YES;
    collectionView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [view addSubview:collectionView];
    self.collectionView = collectionView;
    
    NSString *headerIdentifier = NSStringFromClass(ShowHeaderView.class);
    UINib *headerNib = [UINib nibWithNibName:headerIdentifier bundle:nil];
    [collectionView registerNib:headerNib forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:headerIdentifier];
    
    self.view = view;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSURL *sharingURL = [ApplicationConfiguration.sharedApplicationConfiguration sharingURLForShow:self.show];
    if (sharingURL) {
        UIBarButtonItem *shareBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"share"]
                                                                               style:UIBarButtonItemStylePlain
                                                                              target:self
                                                                              action:@selector(shareContent:)];
        shareBarButtonItem.accessibilityLabel = PlaySRGAccessibilityLocalizedString(@"Share", @"Share button label on player view");
        self.navigationItem.rightBarButtonItem = shareBarButtonItem;
    }
    
    [self updateAppearanceForSize:self.view.frame.size];
    
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(accessibilityVoiceOverStatusChanged:)
                                               name:UIAccessibilityVoiceOverStatusDidChangeNotification
                                             object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.userActivity = [[NSUserActivity alloc] initWithActivityType:[NSBundle.mainBundle.bundleIdentifier stringByAppendingString:@".displaying"]];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    self.userActivity = nil;
    
    self.fromPushNotification = NO;
}

#pragma mark Rotation

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return [super supportedInterfaceOrientations] & UIViewController.play_supportedInterfaceOrientations;
}

#pragma mark Responsiveness

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> _Nonnull context) {
        [self.collectionView.collectionViewLayout invalidateLayout];
        [self updateAppearanceForSize:size];
        
        ShowHeaderView *headerView = (ShowHeaderView *)[self.collectionView supplementaryViewForElementKind:UICollectionElementKindSectionHeader atIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
        if (headerView) {
            [headerView updateAspectRatioWithSize:self.collectionView.frame.size];
        }
    } completion:nil];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
    [super traitCollectionDidChange:previousTraitCollection];
    
    [self.collectionView.collectionViewLayout invalidateLayout];
    ShowHeaderView *headerView = (ShowHeaderView *)[self.collectionView supplementaryViewForElementKind:UICollectionElementKindSectionHeader atIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    if (headerView) {
        [headerView updateAspectRatioWithSize:self.collectionView.frame.size];
    }
    
    [self updateAppearanceForSize:self.view.frame.size];
}

#pragma mark Status bar

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

#pragma mark Overrides

- (void)prepareRefreshWithRequestQueue:(SRGRequestQueue *)requestQueue page:(SRGPage *)page completionHandler:(ListRequestPageCompletionHandler)completionHandler
{
    SRGPaginatedEpisodeCompositionCompletionBlock completionBlock = ^(SRGEpisodeComposition * _Nullable episodeComposition, SRGPage * _Nonnull page, SRGPage * _Nullable nextPage, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == %@ || %K == %@", @keypath(SRGMedia.new, contentType), @(SRGContentTypeEpisode), @keypath(SRGMedia.new, contentType), @(SRGContentTypeScheduledLivestream)];
        
        NSMutableArray *medias = [NSMutableArray array];
        for (SRGEpisode *episode in episodeComposition.episodes) {
            NSArray *mediasForEpisode = [episode.medias filteredArrayUsingPredicate:predicate];
            [medias addObjectsFromArray:mediasForEpisode];
        }
        
        if (episodeComposition.show) {
            self.show = episodeComposition.show;
            
            [self updateAppearanceForSize:self.view.frame.size];
        }
        
        completionHandler(medias.copy, page, nextPage, HTTPResponse, error);
    };
    
    NSUInteger pageSize = ApplicationConfiguration.sharedApplicationConfiguration.pageSize;
    
    SRGPageRequest *request = [[[SRGDataProvider.currentDataProvider latestEpisodesForShowWithURN:self.show.URN maximumPublicationDay:nil completionBlock:completionBlock] requestWithPageSize:pageSize] requestWithPage:page];
    [requestQueue addRequest:request resume:YES];
}

#pragma mark UIResponder (ActivityContinuation)

- (void)updateUserActivityState:(NSUserActivity *)userActivity
{
    [super updateUserActivityState:userActivity];
    
    userActivity.title = [NSString stringWithFormat:NSLocalizedString(@"Display %@ episodes", @"User activity title when displaying a show page"), self.show.title];
    [userActivity addUserInfoEntriesFromDictionary:@{ @"URNString" : self.show.URN,
                                                      @"SRGShowData" : [NSKeyedArchiver archivedDataWithRootObject:self.show requiringSecureCoding:NO error:NULL],
                                                      @"applicationVersion" : [NSBundle.mainBundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"] }];
    userActivity.webpageURL = [ApplicationConfiguration.sharedApplicationConfiguration sharingURLForShow:self.show];
    
    userActivity.eligibleForPrediction = YES;
    userActivity.persistentIdentifier = self.show.URN;
    NSString *suggestedInvocationPhraseFormat = (self.show.transmission == SRGTransmissionRadio) ? NSLocalizedString(@"Listen to %@", @"Suggested invocation phrase to listen to a show") : NSLocalizedString(@"Watch %@", @"Suggested invocation phrase to watch a show");
    userActivity.suggestedInvocationPhrase = [NSString stringWithFormat:suggestedInvocationPhraseFormat, self.show.title];
}

#pragma mark UI

- (void)updateAppearanceForSize:(CGSize)size
{
    // Display the title and an empty image when the show header is not visible (so that the view never feels empty, and
    // so that the show title can be read)
    if ([ShowHeaderView heightForShow:self.show withSize:size] == 0.f) {
        self.title = self.show.title;
        self.emptyCollectionImage = [UIImage imageNamed:@"media-background"];
    }
    else {
        self.title = UIAccessibilityIsVoiceOverRunning() ? self.show.title : nil;
        self.emptyCollectionImage = nil;
    }
    
    NSString *broadcastInformationMessage = self.show.broadcastInformation.message;
    if (broadcastInformationMessage) {
        self.emptyCollectionTitle = broadcastInformationMessage;
        self.emptyCollectionSubtitle = @"";
    }
    else {
        self.emptyCollectionTitle = nil;
        self.emptyCollectionSubtitle = nil;
    }
    
    [self.collectionView reloadEmptyDataSet];
}

#pragma mark Actions

- (IBAction)shareContent:(UIBarButtonItem *)barButtonItem
{
    if (! self.show) {
        return;
    }
    
    SharingItem *sharingItem = [SharingItem sharingItemForShow:self.show];
    if (! sharingItem) {
        return;
    }
    
    UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithSharingItem:sharingItem
                                                                                                      source:AnalyticsSourceButton
                                                                                            inViewController:self
                                                                                         withCompletionBlock:nil];
    activityViewController.modalPresentationStyle = UIModalPresentationPopover;
    
    UIPopoverPresentationController *popoverPresentationController = activityViewController.popoverPresentationController;
    popoverPresentationController.barButtonItem = barButtonItem;
    
    [self presentViewController:activityViewController animated:YES completion:nil];
}

#pragma mark DZNEmptyDataSetSource protocol

- (CGFloat)verticalOffsetForEmptyDataSet:(UIScrollView *)scrollView
{
    CGFloat offset = [super verticalOffsetForEmptyDataSet:scrollView];
    return offset + [ShowHeaderView heightForShow:self.show withSize:scrollView.frame.size] / 2.f;
}

- (NSAttributedString *)buttonTitleForEmptyDataSet:(UIScrollView *)scrollView forState:(UIControlState)state
{
    if (self.show.broadcastInformation.URL) {
        NSDictionary *attributes = @{ NSFontAttributeName : [SRGFont fontWithStyle:SRGFontStyleH2],
                                      NSForegroundColorAttributeName : UIColor.whiteColor };
        return [[NSAttributedString alloc] initWithString:NSLocalizedString(@"Show more", @"Show more button label when a link is available for broadcast information.") attributes:attributes];
    }
    else {
        return nil;
    }
}

#pragma mark DZNEmptyDataSetDelegate protocol

- (void)emptyDataSet:(UIScrollView *)scrollView didTapButton:(UIButton *)button
{
    NSURL *broadcastInformationURL = self.show.broadcastInformation.URL;
    if (broadcastInformationURL) {
        [UIApplication.sharedApplication play_openURL:broadcastInformationURL withCompletionHandler:nil];
    }
}

#pragma mark SRGAnalyticsViewTracking protocols

- (NSString *)srg_pageViewTitle
{
    return self.show.title;
}

- (NSArray<NSString *> *)srg_pageViewLevels
{
    NSString *level1 = (self.show.transmission == SRGTransmissionRadio) ? AnalyticsPageLevelAudio : AnalyticsPageLevelVideo;
    return @[ AnalyticsPageLevelPlay, level1, AnalyticsPageLevelShow ];
}

#pragma mark UICollectionViewDataSource protocol

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
        ShowHeaderView *headerView = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:NSStringFromClass(ShowHeaderView.class) forIndexPath:indexPath];
        [headerView updateAspectRatioWithSize:collectionView.frame.size];
        return headerView;
    }
    else {
        return [super collectionView:collectionView viewForSupplementaryElementOfKind:kind atIndexPath:indexPath];
    }
}

#pragma mark UICollectionViewDelegateFlowLayout protocol

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section
{
    CGSize size = collectionView.frame.size;
    return CGSizeMake(size.width, [ShowHeaderView heightForShow:self.show withSize:size]);
}

#pragma mark UICollectionViewDelegate protocol

- (void)collectionView:(UICollectionView *)collectionView willDisplaySupplementaryView:(UICollectionReusableView *)view forElementKind:(NSString *)elementKind atIndexPath:(NSIndexPath *)indexPath
{
    if ([view isKindOfClass:ShowHeaderView.class]) {
        ShowHeaderView *headerView = (ShowHeaderView *)view;
        headerView.show = self.show;
    }
}

#pragma mark Notifications

- (void)accessibilityVoiceOverStatusChanged:(NSNotification *)notification
{
    [self updateAppearanceForSize:self.view.frame.size];
    [self.collectionView reloadData];
}

#pragma mark SRGAnalyticsViewTracking protocol

- (BOOL)srg_isOpenedFromPushNotification
{
    return self.fromPushNotification;
}

@end
