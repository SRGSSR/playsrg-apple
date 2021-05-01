//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "ModuleViewController.h"

#import "ActivityItemSource.h"
#import "AnalyticsConstants.h"
#import "ApplicationConfiguration.h"
#import "Banner.h"
#import "Layout.h"
#import "ModuleHeaderView.h"
#import "NSBundle+PlaySRG.h"
#import "PlayAppDelegate.h"
#import "UIColor+PlaySRG.h"
#import "UIView+PlaySRG.h"
#import "UIViewController+PlaySRG.h"
#import "UIWindow+PlaySRG.h"

@import libextobjc;

@interface ModuleViewController ()

@property (nonatomic) SRGModule *module;

@property (nonatomic, weak) UIBarButtonItem *shareBarButtonItem;

@end

@implementation ModuleViewController

#pragma mark Object lifecycle

- (instancetype)initWithModule:(SRGModule *)module
{
    if (self = [super init]) {
        self.module = module;
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
    
    NSString *headerIdentifier = NSStringFromClass(ModuleHeaderView.class);
    UINib *headerNib = [UINib nibWithNibName:headerIdentifier bundle:nil];
    [collectionView registerNib:headerNib forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:headerIdentifier];
    
    self.view = view;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSURL *sharingURL = [ApplicationConfiguration.sharedApplicationConfiguration sharingURLForModule:self.module];
    if (sharingURL) {
        UIBarButtonItem *shareBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"share-22"]
                                                                               style:UIBarButtonItemStylePlain
                                                                              target:self
                                                                              action:@selector(shareContent:)];
        shareBarButtonItem.accessibilityLabel = PlaySRGAccessibilityLocalizedString(@"Share", @"Share button label on player view");
        self.navigationItem.rightBarButtonItems = @[ shareBarButtonItem ];
        self.shareBarButtonItem = shareBarButtonItem;
    }
    
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

#pragma mark Responsiveness

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        [self.collectionView.collectionViewLayout invalidateLayout];
        [self updateAppearanceForSize:size];
    } completion:nil];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
    [super traitCollectionDidChange:previousTraitCollection];
    
    [self.collectionView.collectionViewLayout invalidateLayout];
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
    NSUInteger pageSize = ApplicationConfiguration.sharedApplicationConfiguration.pageSize;
    SRGPageRequest *request = [[[SRGDataProvider.currentDataProvider latestMediasForModuleWithURN:self.module.URN completionBlock:completionHandler] requestWithPageSize:pageSize] requestWithPage:page];
    [requestQueue addRequest:request resume:YES];
}

#pragma mark UI

- (void)updateAppearanceForSize:(CGSize)size
{
    // Display the title and an empty image when the module header is not visible (so that the view never feels empty, and
    // so that the module title can be read)
    if ([ModuleHeaderView heightForModule:self.module withSize:size] == 0.f) {
        self.title = self.module.title;
        self.emptyCollectionImage = [UIImage imageNamed:@"media-90"];
    }
    else {
        self.title = UIAccessibilityIsVoiceOverRunning() ? self.module.title : nil;
        self.emptyCollectionImage = nil;
    }
    
    [self.collectionView reloadEmptyDataSet];
}

#pragma mark Actions

- (IBAction)shareContent:(UIBarButtonItem *)barButtonItem
{
    if (! self.module) {
        return;
    }
    
    NSURL *sharingURL = [ApplicationConfiguration.sharedApplicationConfiguration sharingURLForModule:self.module];
    if (! sharingURL) {
        return;
    }
    
    ActivityItemSource *activityItemSource = [[ActivityItemSource alloc] initWithModule:self.module URL:sharingURL];
    UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:@[ activityItemSource ] applicationActivities:nil];
    activityViewController.excludedActivityTypes = @[ UIActivityTypePrint,
                                                      UIActivityTypeAssignToContact,
                                                      UIActivityTypeSaveToCameraRoll,
                                                      UIActivityTypePostToFlickr,
                                                      UIActivityTypePostToVimeo,
                                                      UIActivityTypePostToTencentWeibo ];
    activityViewController.completionWithItemsHandler = ^(UIActivityType __nullable activityType, BOOL completed, NSArray * __nullable returnedItems, NSError * __nullable activityError) {
        if (! completed) {
            return;
        }
        
        SRGAnalyticsHiddenEventLabels *labels = [[SRGAnalyticsHiddenEventLabels alloc] init];
        labels.type = activityType;
        labels.source = AnalyticsSourceButton;
        labels.value = self.module.URN;
        [SRGAnalyticsTracker.sharedTracker trackHiddenEventWithName:AnalyticsTitleSharingModule labels:labels];
        
        if ([activityType isEqualToString:UIActivityTypeCopyToPasteboard]) {
            [Banner showWithStyle:BannerStyleInfo
                          message:NSLocalizedString(@"The content has been copied to the clipboard.", @"Message displayed when some content (media, show, etc.) has been copied to the clipboard")
                            image:nil
                           sticky:NO
                 inViewController:self];
        }
    };
    
    activityViewController.modalPresentationStyle = UIModalPresentationPopover;
    
    UIPopoverPresentationController *popoverPresentationController = activityViewController.popoverPresentationController;
    popoverPresentationController.barButtonItem = self.shareBarButtonItem;
    
    [self presentViewController:activityViewController animated:YES completion:nil];
}

#pragma mark DZNEmptyDataSetSource protocol

- (CGFloat)verticalOffsetForEmptyDataSet:(UIScrollView *)scrollView
{
    CGFloat offset = [super verticalOffsetForEmptyDataSet:scrollView];
    return offset + [ModuleHeaderView heightForModule:self.module withSize:scrollView.frame.size] / 2.f;
}

#pragma mark SRGAnalyticsViewTracking protocol

- (NSString *)srg_pageViewTitle
{
    return self.module.title;
}

- (NSArray<NSString *> *)srg_pageViewLevels
{
    return @[ AnalyticsPageLevelPlay, AnalyticsPageLevelVideo, AnalyticsPageLevelEvent ];
}

#pragma mark UICollectionViewDataSource protocol

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
        return [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:NSStringFromClass(ModuleHeaderView.class) forIndexPath:indexPath];
    }
    else {
        return [super collectionView:collectionView viewForSupplementaryElementOfKind:kind atIndexPath:indexPath];
    }
}

#pragma mark UICollectionViewDelegateFlowLayout protocol

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section
{
    CGSize size = collectionView.frame.size;
    return CGSizeMake(size.width, [ModuleHeaderView heightForModule:self.module withSize:size]);
}

#pragma mark UICollectionViewDelegate protocol

- (void)collectionView:(UICollectionView *)collectionView willDisplaySupplementaryView:(UICollectionReusableView *)view forElementKind:(NSString *)elementKind atIndexPath:(NSIndexPath *)indexPath
{
    if ([view isKindOfClass:ModuleHeaderView.class]) {
        ModuleHeaderView *headerView = (ModuleHeaderView *)view;
        headerView.module = self.module;
    }
}

#pragma mark Notifications

- (void)accessibilityVoiceOverStatusChanged:(NSNotification *)notification
{
    [self updateAppearanceForSize:self.view.frame.size];
    [self.collectionView reloadData];
}

@end
