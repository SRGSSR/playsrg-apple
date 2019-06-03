//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "BaseViewController.h"

#import "ActivityItemSource.h"
#import "ApplicationConfiguration.h"
#import "Banner.h"
#import "Download.h"
#import "Favorites.h"
#import "GoogleCast.h"
#import "HomeTopicViewController.h"
#import "MediaPlayerViewController.h"
#import "MediaPreviewViewController.h"
#import "ModuleViewController.h"
#import "PlayErrors.h"
#import "Previewing.h"
#import "ShowViewController.h"
#import "UIViewController+PlaySRG.h"
#import "UIViewController+PlaySRG_Private.h"
#import "WatchLater.h"

#import <objc/runtime.h>
#import <libextobjc/libextobjc.h>

NSString *PageViewTitleForViewController(UIViewController *viewController)
{
    if ([viewController conformsToProtocol:@protocol(SRGAnalyticsViewTracking)]) {
        UIViewController<SRGAnalyticsViewTracking> *trackedViewController = (UIViewController<SRGAnalyticsViewTracking> *)viewController;
        return trackedViewController.srg_pageViewTitle;
    }
    else {
        return viewController.title;
    }
}

@implementation BaseViewController

#pragma mark Stubs

- (AnalyticsPageType)pageType
{
    return AnalyticsPageTypeNone;
}

#pragma mark Accessibility

- (BOOL)accessibilityPerformEscape
{
    if (self.navigationController.viewControllers.count > 1) {
        [self.navigationController popViewControllerAnimated:YES];
        return YES;
    }
    else if (self.presentingViewController) {
        [self dismissViewControllerAnimated:YES completion:nil];
        return YES;
    }
    else {
        return NO;
    }
}

#pragma mark SRGAnalyticsViewTracking protocol

- (NSString *)srg_pageViewTitle
{
    return self.title;
}

- (NSArray<NSString *> *)srg_pageViewLevels
{
    NSMutableArray<NSString *> *levels = [NSMutableArray array];
    
    // Climb up the view controller hierarchy and store levels in reverse order
    UIViewController *parentViewController = self.parentViewController;
    while (parentViewController) {
        // Navigation. Always remove the last level (taken into account one iteration earlier)
        if ([parentViewController isKindOfClass:UINavigationController.class]) {
            UINavigationController *navigationController = (UINavigationController *)parentViewController;
            NSArray<UIViewController *> *viewControllers = [[navigationController.viewControllers arrayByRemovingLastObject] reverseObjectEnumerator].allObjects;
            NSMutableArray<NSString *> *titles = [NSMutableArray array];
            [viewControllers enumerateObjectsUsingBlock:^(UIViewController * _Nonnull viewController, NSUInteger idx, BOOL * _Nonnull stop) {
                NSString *title = PageViewTitleForViewController(viewController);
                if (title) {
                    [titles addObject:title];
                }
            }];
            [levels addObjectsFromArray:titles];
        }
        else {
            NSString *title = PageViewTitleForViewController(parentViewController);
            if (title) {
                [levels addObject:parentViewController.title];
            }
        }
        
        parentViewController = parentViewController.parentViewController;
    }
    
    // Add the top level (if any)
    NSString *pageType = AnalyticsNameForPageType(self.pageType);
    if (pageType) {
        [levels addObject:pageType];
    }
    
    // Reverse levels since built in reverse order
    return [levels reverseObjectEnumerator].allObjects;
}

#pragma mark UIViewControllerPreviewingDelegate protocol

- (UIViewController *)previewingContext:(id<UIViewControllerPreviewing>)previewingContext viewControllerForLocation:(CGPoint)location
{
    UIView *sourceView = [previewingContext sourceView];
    if (! [sourceView conformsToProtocol:@protocol(Previewing)]) {
        return nil;
    }
    
    id previewObject = [(id<Previewing>)sourceView previewObject];
    if (! previewObject) {
        return nil;
    }
    
    UIViewController *viewController = nil;
    if ([previewObject isKindOfClass:SRGMedia.class]) {
        viewController = [[MediaPreviewViewController alloc] initWithMedia:previewObject];
    }
    else if ([previewObject isKindOfClass:SRGModule.class]) {
        viewController = [[ModuleViewController alloc] initWithModule:previewObject];
    }
    else if ([previewObject isKindOfClass:SRGShow.class]) {
        viewController = [[ShowViewController alloc] initWithShow:previewObject fromPushNotification:NO];
    }
    else if ([previewObject isKindOfClass:SRGTopic.class]) {
        viewController = [[HomeTopicViewController alloc] initWithTopic:previewObject];
    }
    else {
        return nil;
    }
    
    viewController.play_previewingContext = previewingContext;
    return viewController;
}

- (void)previewingContext:(id<UIViewControllerPreviewing>)previewingContext commitViewController:(UIViewController *)viewControllerToCommit
{
    if ([viewControllerToCommit isKindOfClass:MediaPreviewViewController.class]) {
        MediaPreviewViewController *mediaPreviewViewController = (MediaPreviewViewController *)viewControllerToCommit;
        UIView *sourceView = previewingContext.sourceView;
        [sourceView.nearestViewController play_presentMediaPlayerFromLetterboxController:mediaPreviewViewController.letterboxController fromPushNotification:NO animated:YES completion:nil];
    }
    else if ([viewControllerToCommit isKindOfClass:ModuleViewController.class]
                || [viewControllerToCommit isKindOfClass:ShowViewController.class]
                || [viewControllerToCommit isKindOfClass:HomeTopicViewController.class]) {
        [self.navigationController pushViewController:viewControllerToCommit animated:YES];
    }
}

#pragma mark 3D Touch fallback

- (void)showPreviewForSourceView:(UIView *)sourceView
{
    if (! [sourceView conformsToProtocol:@protocol(Previewing)]) {
        return;
    }
    
    id previewObject = [(id<Previewing>)sourceView previewObject];
    if (! previewObject) {
        return;
    }
    
    UIAlertController *alertController = nil;
    
    if ([previewObject isKindOfClass:SRGMedia.class]) {
        SRGMedia *media = previewObject;
        
        NSString *message = (media.show.title && ! [media.title containsString:media.show.title]) ? media.show.title : nil;
        alertController = [UIAlertController alertControllerWithTitle:media.title message:message preferredStyle:UIAlertControllerStyleActionSheet];
        
        if (WatchLaterCanStoreMediaMetadata(media)) {
            BOOL inWatchLaterList = WatchLaterContainsMediaMetadata(media);
            [alertController addAction:[UIAlertAction actionWithTitle:inWatchLaterList ? NSLocalizedString(@"Remove from \"Watch later\"", @"Button label to remove a media from the watch later list, from the media long-press menu") : NSLocalizedString(@"Add to \"Watch later\"", @"Button label to add a media to the watch later list, from the media long-press menu") style:inWatchLaterList ? UIAlertActionStyleDestructive : UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                WatchLaterToggleMediaMetadata(media, ^(BOOL added, NSError * _Nullable error) {
                    if (! error) {
                        AnalyticsTitle analyticsTitle = added ? AnalyticsTitleWatchLaterAdd : AnalyticsTitleWatchLaterRemove;
                        SRGAnalyticsHiddenEventLabels *labels = [[SRGAnalyticsHiddenEventLabels alloc] init];
                        labels.source = AnalyticsSourceLongPress;
                        labels.value = media.URN;
                        [SRGAnalyticsTracker.sharedTracker trackHiddenEventWithName:analyticsTitle labels:labels];
                        
                        [Banner showWatchLaterAdded:added forItemWithName:media.title inViewController:self];
                    }
                });
            }]];
        }
        
        BOOL downloadable = [Download canDownloadMedia:media];
        if (downloadable) {
            Download *download = [Download downloadForMedia:media];
            BOOL downloaded = (download != nil);
            [alertController addAction:[UIAlertAction actionWithTitle:downloaded ? NSLocalizedString(@"Remove from downloads", @"Button label to remove a download from the media long-press menu") : NSLocalizedString(@"Add to downloads", @"Button label to add a download from the media long-press menu") style:downloaded ? UIAlertActionStyleDestructive : UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                if (downloaded) {
                    [Download removeDownload:download];
                }
                else {
                    [Download addDownloadForMedia:media];
                }
                
                // Use !downloaded since the status has been reversed
                AnalyticsTitle analyticsTitle = (! downloaded) ? AnalyticsTitleDownloadAdd : AnalyticsTitleDownloadRemove;
                SRGAnalyticsHiddenEventLabels *labels = [[SRGAnalyticsHiddenEventLabels alloc] init];
                labels.source = AnalyticsSourceLongPress;
                labels.value = media.URN;
                [SRGAnalyticsTracker.sharedTracker trackHiddenEventWithName:analyticsTitle labels:labels];
            }]];
        }
        
        NSURL *sharingURL = [ApplicationConfiguration.sharedApplicationConfiguration sharingURLForMediaMetadata:media atTime:kCMTimeZero];
        if (sharingURL) {
            [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Share", @"Button label of the sharing choice in the media long-press menu") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                ActivityItemSource *activityItemSource = [[ActivityItemSource alloc] initWithMedia:media URL:sharingURL];
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
                    labels.source = AnalyticsSourceLongPress;
                    labels.value = media.URN;
                    labels.extraValue1 = AnalyticsTypeValueSharingContent;
                    [SRGAnalyticsTracker.sharedTracker trackHiddenEventWithName:AnalyticsTitleSharing labels:labels];
                    
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
                popoverPresentationController.sourceView = sourceView;
                popoverPresentationController.sourceRect = [sourceView bounds];
                
                [self presentViewController:activityViewController animated:YES completion:nil];
            }]];
        }
        
        if (self.navigationController && ! ApplicationConfiguration.sharedApplicationConfiguration.moreEpisodesHidden && media.show) {
            [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"More episodes", @"Button label to open the show episode page from the long-press menu") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                ShowViewController *showViewController = [[ShowViewController alloc] initWithShow:media.show fromPushNotification:NO];
                [self.navigationController pushViewController:showViewController animated:YES];
            }]];
        }
        
        [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Open", @"Button label to open a media from the start from the long-press menu") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            MediaPlayerViewController *mediaPlayerViewController = [[MediaPlayerViewController alloc] initWithMedia:media position:nil fromPushNotification:NO];
            [self presentViewController:mediaPlayerViewController animated:YES completion:nil];
        }]];
        [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"Label of the button to close the media long-press menu") style:UIAlertActionStyleCancel handler:nil]];
    }
    else if ([previewObject isKindOfClass:SRGShow.class]) {
        SRGShow *show = previewObject;
        
        BOOL isFavorite = FavoritesContainsShow(show);
        
        alertController = [UIAlertController alertControllerWithTitle:show.title message:nil preferredStyle:UIAlertControllerStyleActionSheet];
        [alertController addAction:[UIAlertAction actionWithTitle:isFavorite ? NSLocalizedString(@"Remove from favorites", @"Button label to remove a show from favorites in the show long-press menu") : NSLocalizedString(@"Add to favorites", @"Button label to add a show to favorites in the show long-press menu") style:isFavorite ? UIAlertActionStyleDestructive : UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            FavoritesToggleShow(show);
            
            // Use !isFavorite since favorite status has been reversed
            AnalyticsTitle analyticsTitle = (! isFavorite) ? AnalyticsTitleFavoriteAdd : AnalyticsTitleFavoriteRemove;
            SRGAnalyticsHiddenEventLabels *labels = [[SRGAnalyticsHiddenEventLabels alloc] init];
            labels.source = AnalyticsSourceLongPress;
            labels.value = show.URN;
            [SRGAnalyticsTracker.sharedTracker trackHiddenEventWithName:analyticsTitle labels:labels];
            
            [Banner showFavorite:! isFavorite forItemWithName:show.title inViewController:self];
        }]];
        
        NSURL *sharingURL = [ApplicationConfiguration.sharedApplicationConfiguration sharingURLForShow:show];
        if (sharingURL) {
            [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Share", @"Button label of the sharing choice in the show long-press menu") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                ActivityItemSource *activityItemSource = [[ActivityItemSource alloc] initWithShow:show URL:sharingURL];
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
                    labels.source = AnalyticsSourceLongPress;
                    labels.value = show.URN;
                    [SRGAnalyticsTracker.sharedTracker trackHiddenEventWithName:AnalyticsTitleSharingShow labels:labels];
                    
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
                popoverPresentationController.sourceView = sourceView;
                popoverPresentationController.sourceRect = [sourceView bounds];
                
                [self presentViewController:activityViewController animated:YES completion:nil];
            }]];
        }
        
        if (self.navigationController) {
            [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Open", @"Button label to open a show from the from the long-press menu") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                ShowViewController *showViewController = [[ShowViewController alloc] initWithShow:show fromPushNotification:NO];
                [self.navigationController pushViewController:showViewController animated:YES];
            }]];
        }
        [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"Label of the button to close the show long-press menu") style:UIAlertActionStyleCancel handler:nil]];
    }
    else {
        return;
    }
    
    UIPopoverPresentationController *popoverPresentationController = alertController.popoverPresentationController;
    popoverPresentationController.sourceView = sourceView;
    popoverPresentationController.sourceRect = [sourceView bounds];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

@end
