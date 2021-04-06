//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "BaseViewController.h"

#import "ActivityItemSource.h"
#import "AnalyticsConstants.h"
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
#import "WatchLater.h"

#import <objc/runtime.h>

@import libextobjc;
@import SRGAnalytics;

static void commonInit(BaseViewController *self);

// Inner class conforming to `UIPopoverPresentationControllerDelegate` to avoid having `BaseViewController` conform to
// it.
@interface BaseViewControllerPresentationControllerDelegate : NSObject <UIPopoverPresentationControllerDelegate>

@end

@implementation BaseViewControllerPresentationControllerDelegate

#pragma mark UIPopoverPresentationControllerDelegate protocol

- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller traitCollection:(UITraitCollection *)traitCollection
{
    return UIModalPresentationFormSheet;
}

@end

@interface BaseViewController () <UIContextMenuInteractionDelegate>

@property (nonatomic, readonly) BaseViewControllerPresentationControllerDelegate *presentationControllerDelegate;

@end

@implementation BaseViewController

@synthesize presentationControllerDelegate = _presentationControllerDelegate;

#pragma mark Object lifecycle

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        commonInit(self);
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    if (self = [super initWithCoder:coder]) {
        commonInit(self);
    }
    return self;
}

#pragma mark Getters and setters

- (BaseViewControllerPresentationControllerDelegate *)presentationControllerDelegate
{
    if (! _presentationControllerDelegate) {
        _presentationControllerDelegate = [[BaseViewControllerPresentationControllerDelegate alloc] init];
    }
    return _presentationControllerDelegate;
}

#pragma mark Subclassing hooks

- (void)updateForContentSizeCategory
{}

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

#pragma mark Context menus

- (UIMenu *)contextMenuForMedia:(SRGMedia *)media
{
    NSMutableArray<UIMenuElement *> *menuActions = [NSMutableArray array];
    
    WatchLaterAction action = WatchLaterAllowedActionForMediaMetadata(media);
    if (action != WatchLaterActionNone) {
        BOOL isRemoval = (action == WatchLaterActionRemove);
        NSString *addActionTitle = (media.mediaType == SRGMediaTypeAudio) ? NSLocalizedString(@"Listen later", @"Context menu action to add an audio to the later list") : NSLocalizedString(@"Watch later", @"Context menu action to add a video to the later list");
        UIAction *watchLaterAction = [UIAction actionWithTitle:isRemoval ? NSLocalizedString(@"Delete from \"Later\"", @"Context menu action to delete a media from the later list") : addActionTitle image:isRemoval ? [UIImage imageNamed:@"watch_later_full-22"] : [UIImage imageNamed:@"watch_later-22"] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            WatchLaterToggleMediaMetadata(media, ^(BOOL added, NSError * _Nullable error) {
                if (! error) {
                    AnalyticsTitle analyticsTitle = added ? AnalyticsTitleWatchLaterAdd : AnalyticsTitleWatchLaterRemove;
                    SRGAnalyticsHiddenEventLabels *labels = [[SRGAnalyticsHiddenEventLabels alloc] init];
                    labels.source = AnalyticsSourcePeekMenu;
                    labels.value = media.URN;
                    [SRGAnalyticsTracker.sharedTracker trackHiddenEventWithName:analyticsTitle labels:labels];
                    
                    [Banner showWatchLaterAdded:added forItemWithName:media.title inViewController:nil /* Not 'self' since dismissed */];
                }
            });
        }];
        if (isRemoval) {
            watchLaterAction.attributes = UIMenuElementAttributesDestructive;
        }
        [menuActions addObject:watchLaterAction];
    }
    
    BOOL downloadable = [Download canDownloadMedia:media];
    if (downloadable) {
        Download *download = [Download downloadForMedia:media];
        BOOL downloaded = (download != nil);
        UIAction *downloadAction = [UIAction actionWithTitle:downloaded ? NSLocalizedString(@"Delete from downloads", @"Context menu action to delete a media from the downloads") : NSLocalizedString(@"Add to downloads", @"Context menu action to add a media to the downloads") image:downloaded ? [UIImage imageNamed:@"downloadable_full-22"] : [UIImage imageNamed:@"downloadable-22"] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            if (downloaded) {
                [Download removeDownload:download];
            }
            else {
                [Download addDownloadForMedia:media];
            }
            
            // Use !downloaded since the status has been reversed
            AnalyticsTitle analyticsTitle = ! downloaded ? AnalyticsTitleDownloadAdd : AnalyticsTitleDownloadRemove;
            SRGAnalyticsHiddenEventLabels *labels = [[SRGAnalyticsHiddenEventLabels alloc] init];
            labels.source = AnalyticsSourcePeekMenu;
            labels.value = media.URN;
            [SRGAnalyticsTracker.sharedTracker trackHiddenEventWithName:analyticsTitle labels:labels];
        }];
        if (downloaded) {
            downloadAction.attributes = UIMenuElementAttributesDestructive;
        }
        [menuActions addObject:downloadAction];
    }
    
    NSURL *sharingURL = [ApplicationConfiguration.sharedApplicationConfiguration sharingURLForMediaMetadata:media atTime:kCMTimeZero];
    if (sharingURL) {
        UIAction *shareAction = [UIAction actionWithTitle:NSLocalizedString(@"Share", @"Context menu action to share a media") image:[UIImage imageNamed:@"share-22"] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
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
                labels.source = AnalyticsSourcePeekMenu;
                labels.value = media.URN;
                labels.extraValue1 = AnalyticsTypeValueSharingContent;
                [SRGAnalyticsTracker.sharedTracker trackHiddenEventWithName:AnalyticsTitleSharingMedia labels:labels];
                
                if ([activityType isEqualToString:UIActivityTypeCopyToPasteboard]) {
                    [Banner showWithStyle:BannerStyleInfo
                                  message:NSLocalizedString(@"The content has been copied to the clipboard.", @"Message displayed when some content (media, show, etc.) has been copied to the clipboard")
                                    image:nil
                                   sticky:NO
                         inViewController:self];
                }
            };
            
            UIPopoverPresentationController *popoverPresentationController = activityViewController.popoverPresentationController;
            popoverPresentationController.sourceView = self.view;
            popoverPresentationController.delegate = self.presentationControllerDelegate;
            
            [self presentViewController:activityViewController animated:YES completion:nil];
        }];
        [menuActions addObject:shareAction];
    }
    
    if (self.navigationController && ! ApplicationConfiguration.sharedApplicationConfiguration.moreEpisodesHidden && media.show) {
        UIAction *moreEpisodesAction = [UIAction actionWithTitle:NSLocalizedString(@"More episodes", @"Context menu action to open more episodes associated with a media") image:[UIImage imageNamed:@"episodes-22"] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            ShowViewController *showViewController = [[ShowViewController alloc] initWithShow:media.show fromPushNotification:NO];
            [self.navigationController pushViewController:showViewController animated:YES];
        }];
        [menuActions addObject:moreEpisodesAction];
    }
    
    return [UIMenu menuWithTitle:@"" children:menuActions.copy];
}

- (UIMenu *)contextMenuForModule:(SRGModule *)module
{
    NSMutableArray<UIMenuElement *> *menuActions = [NSMutableArray array];
    
    NSURL *sharingURL = [ApplicationConfiguration.sharedApplicationConfiguration sharingURLForModule:module];
    if (sharingURL) {
        UIAction *shareAction = [UIAction actionWithTitle:NSLocalizedString(@"Share", @"Context menu action to share a module") image:[UIImage imageNamed:@"share-22"] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            ActivityItemSource *activityItemSource = [[ActivityItemSource alloc] initWithModule:module URL:sharingURL];
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
                labels.source = AnalyticsSourcePeekMenu;
                labels.value = module.URN;
                [SRGAnalyticsTracker.sharedTracker trackHiddenEventWithName:AnalyticsTitleSharingModule labels:labels];
                
                if ([activityType isEqualToString:UIActivityTypeCopyToPasteboard]) {
                    [Banner showWithStyle:BannerStyleInfo
                                  message:NSLocalizedString(@"The content has been copied to the clipboard.", @"Message displayed when some content (media, show, etc.) has been copied to the clipboard")
                                    image:nil
                                   sticky:NO
                         inViewController:self];
                }
            };
            
            UIPopoverPresentationController *popoverPresentationController = activityViewController.popoverPresentationController;
            popoverPresentationController.sourceView = self.view;
            popoverPresentationController.delegate = self.presentationControllerDelegate;
            
            [self presentViewController:activityViewController animated:YES completion:nil];
        }];
        [menuActions addObject:shareAction];
    }
    
    return [UIMenu menuWithTitle:@"" children:menuActions.copy];
}

- (UIMenu *)contextMenuForShow:(SRGShow *)show
{
    NSMutableArray<UIMenuElement *> *menuActions = [NSMutableArray array];
    
    BOOL isFavorite = FavoritesContainsShow(show);
    UIAction *favoriteAction = [UIAction actionWithTitle:isFavorite ? NSLocalizedString(@"Delete from favorites", @"Context menu action to delete a show from favorites") : NSLocalizedString(@"Add to favorites", @"Context menu action to add a show to favorites") image:isFavorite ? [UIImage imageNamed:@"favorite_full-22"] : [UIImage imageNamed:@"favorite-22"] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        FavoritesToggleShow(show);
        
        // Use !isFavorite since favorite status has been reversed
        AnalyticsTitle analyticsTitle = ! isFavorite ? AnalyticsTitleFavoriteAdd : AnalyticsTitleFavoriteRemove;
        SRGAnalyticsHiddenEventLabels *labels = [[SRGAnalyticsHiddenEventLabels alloc] init];
        labels.source = AnalyticsSourcePeekMenu;
        labels.value = show.URN;
        [SRGAnalyticsTracker.sharedTracker trackHiddenEventWithName:analyticsTitle labels:labels];
        
        [Banner showFavorite:! isFavorite forItemWithName:show.title inViewController:self];
    }];
    if (isFavorite) {
        favoriteAction.attributes = UIMenuElementAttributesDestructive;
    }
    [menuActions addObject:favoriteAction];
    
    NSURL *sharingURL = [ApplicationConfiguration.sharedApplicationConfiguration sharingURLForShow:show];
    if (sharingURL) {
        UIAction *shareAction = [UIAction actionWithTitle:NSLocalizedString(@"Share", @"Context menu action to share a show") image:[UIImage imageNamed:@"share-22"] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
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
                labels.source = AnalyticsSourcePeekMenu;
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
            
            UIPopoverPresentationController *popoverPresentationController = activityViewController.popoverPresentationController;
            popoverPresentationController.sourceView = self.view;
            popoverPresentationController.delegate = self.presentationControllerDelegate;
            
            [self presentViewController:activityViewController animated:YES completion:nil];
        }];
        [menuActions addObject:shareAction];
    }
    
    return [UIMenu menuWithTitle:@"" children:menuActions.copy];
}

#pragma mark UIContextMenuInteractionDelegate protocol

- (UIContextMenuConfiguration *)contextMenuInteraction:(UIContextMenuInteraction *)interaction configurationForMenuAtLocation:(CGPoint)location
{
    UIView *sourceView = interaction.view;
    if (! [sourceView conformsToProtocol:@protocol(Previewing)]) {
        return nil;
    }
    
    id previewObject = [(id<Previewing>)sourceView previewObject];
    if (! previewObject) {
        return nil;
    }
    
    if ([previewObject isKindOfClass:SRGMedia.class]) {
        return [UIContextMenuConfiguration configurationWithIdentifier:nil previewProvider:^UIViewController * _Nullable{
            return [[MediaPreviewViewController alloc] initWithMedia:previewObject];
        } actionProvider:^UIMenu * _Nullable(NSArray<UIMenuElement *> * _Nonnull suggestedActions) {
            return [self contextMenuForMedia:previewObject];
        }];
    }
    else if ([previewObject isKindOfClass:SRGModule.class]) {
        return [UIContextMenuConfiguration configurationWithIdentifier:nil previewProvider:^UIViewController * _Nullable{
            return [[ModuleViewController alloc] initWithModule:previewObject];
        } actionProvider:^UIMenu * _Nullable(NSArray<UIMenuElement *> * _Nonnull suggestedActions) {
            return [self contextMenuForModule:previewObject];
        }];
    }
    else if ([previewObject isKindOfClass:SRGShow.class]) {
        return [UIContextMenuConfiguration configurationWithIdentifier:nil previewProvider:^UIViewController * _Nullable{
            return [[ShowViewController alloc] initWithShow:previewObject fromPushNotification:NO];
        } actionProvider:^UIMenu * _Nullable(NSArray<UIMenuElement *> * _Nonnull suggestedActions) {
            return [self contextMenuForShow:previewObject];
        }];
    }
    else {
        return nil;
    }
}

- (void)contextMenuInteraction:(UIContextMenuInteraction *)interaction willPerformPreviewActionForMenuWithConfiguration:(UIContextMenuConfiguration *)configuration animator:(id<UIContextMenuInteractionCommitAnimating>)animator
{
    UIViewController *viewController = animator.previewViewController;
    animator.preferredCommitStyle = UIContextMenuInteractionCommitStylePop;
    [animator addCompletion:^{
        if ([viewController isKindOfClass:MediaPreviewViewController.class]) {
            MediaPreviewViewController *mediaPreviewViewController = (MediaPreviewViewController *)viewController;
            [self play_presentMediaPlayerFromLetterboxController:mediaPreviewViewController.letterboxController withAirPlaySuggestions:NO fromPushNotification:NO animated:YES completion:nil];
        }
        else if ([viewController isKindOfClass:ModuleViewController.class]
                    || [viewController isKindOfClass:ShowViewController.class]
                    || [viewController isKindOfClass:HomeTopicViewController.class]) {
            [self.navigationController pushViewController:viewController animated:YES];
        }
    }];
}

- (UITargetedPreview *)contextMenuInteraction:(UIContextMenuInteraction *)interaction previewForHighlightingMenuWithConfiguration:(UIContextMenuConfiguration *)configuration
{
    UIPreviewParameters *previewParameters = [[UIPreviewParameters alloc] init];
    previewParameters.backgroundColor = self.view.backgroundColor;
    return [[UITargetedPreview alloc] initWithView:interaction.view parameters:previewParameters];
}

#pragma mark Notifications

- (void)baseViewController_contentSizeCategoryDidChange:(NSNotification *)notification
{
    [self updateForContentSizeCategory];
}

@end

static void commonInit(BaseViewController *self)
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(baseViewController_contentSizeCategoryDidChange:)
                                                 name:UIContentSizeCategoryDidChangeNotification
                                               object:nil];
}
