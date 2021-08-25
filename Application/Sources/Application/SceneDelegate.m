//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SceneDelegate.h"

#import "ApplicationConfiguration.h"
#import "ApplicationSettings.h"
#import "ApplicationSettingsConstants.h"
#import "Banner.h"
#import "CalendarViewController.h"
#import "Download.h"
#import "Favorites.h"
#import "GoogleCast.h"
#import "History.h"
#import "MediaPlayerViewController.h"
#import "NSBundle+PlaySRG.h"
#import "NSDateFormatter+PlaySRG.h"
#import "PlayApplication.h"
#import "PlayErrors.h"
#import "PlayFirebaseConfiguration.h"
#import "Playlist.h"
#import "PlayLogger.h"
#import "PlaySRG-Swift.h"
#import "PushService.h"
#import "UIApplication+PlaySRG.h"
#import "UIImage+PlaySRG.h"
#import "UIViewController+PlaySRG.h"
#import "UIWindow+PlaySRG.h"
#import "UpdateInfo.h"
#import "WatchLater.h"

#import <InAppSettingsKit/IASKSettingsReader.h>

@import AirshipCore;
@import AppCenter;
@import AppCenterCrashes;
@import AppCenterDistribute;
@import AVFoundation;
@import Firebase;
@import libextobjc;
@import Mantle;
@import SafariServices;
@import SRGAnalyticsIdentity;
@import SRGAppearance;
@import SRGDataProvider;
@import SRGIdentity;
@import SRGLetterbox;
@import SRGUserData;

#if defined(DEBUG) || defined(NIGHTLY) || defined(BETA)
#import <Fingertips/Fingertips.h>
#endif

@implementation SceneDelegate

#pragma mark Getters and setters

- (TabBarController *)rootTabBarController
{
    return (TabBarController *)self.window.rootViewController;
}

- (void)setPresenterModeEnabled:(BOOL)presenterModeEnabled
{
    SRGLetterboxService.sharedService.mirroredOnExternalScreen = presenterModeEnabled;
    
#if defined(DEBUG) || defined(NIGHTLY) || defined(BETA)
    NSAssert([self.window isKindOfClass:MBFingerTipWindow.class], @"MBFingerTipWindow expected");
    MBFingerTipWindow *window = (MBFingerTipWindow *)self.window;
    window.alwaysShowTouches = presenterModeEnabled;
#endif
}

#pragma mark UIWindowSceneDelegate protocol

- (void)scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session options:(UISceneConnectionOptions *)connectionOptions
{
    if (! [scene isKindOfClass:UIWindowScene.class]) {
        return;
    }
    
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(settingDidChange:)
                                               name:kIASKAppSettingChanged
                                             object:nil];
    
    UIWindowScene *windowScene = (UIWindowScene *)scene;
#if defined(DEBUG) || defined(NIGHTLY) || defined(BETA)
    self.window = [[MBFingerTipWindow alloc] initWithWindowScene:windowScene];
#else
    self.window = [[UIWindow alloc] initWithWindowScene:windowScene];
#endif
    
    self.window.backgroundColor = UIColor.blackColor;
    self.window.accessibilityIgnoresInvertColors = YES;
    
    [self.window makeKeyAndVisible];
    self.window.rootViewController = [[TabBarController alloc] init];
    
    [self setPresenterModeEnabled:ApplicationSettingPresenterModeEnabled()];
    
    UIApplicationShortcutItem *shortcutItem = connectionOptions.shortcutItem;
    if (shortcutItem) {
        [self handleShortcutItem:shortcutItem];
    }
}

- (void)windowScene:(UIWindowScene *)windowScene performActionForShortcutItem:(UIApplicationShortcutItem *)shortcutItem completionHandler:(void (^)(BOOL))completionHandler
{
    BOOL handledShortcutItem = [self handleShortcutItem:shortcutItem];
    completionHandler(handledShortcutItem);
}

// See URL_SCHEMES.md
// Open [scheme]://media/[media_urn] (optional query parameters: channel_id=[channel_id], start_time=[start_position_seconds])
// Open [scheme]://show/[show_urn] (optional query parameter: channel_id=[channel_id])
// Open [scheme]://topic/[topic_urn]
// Open [scheme]://home (optional query parameters: channel_id=[channel_id])
// Open [scheme]://az (optional query parameters: channel_id=[channel_id], index=[index_letter])
// Open [scheme]://bydate (optional query parameters: channel_id=[channel_id], date=[date] with format yyyy-MM-dd)
// Open [scheme]://section/[section_id]
// Open [scheme]://search (optional query parameters: query=[query], media_type=[audio|video])
// Open [scheme]://link?url=[url]
// Open [scheme]://[play_website_url] (use "parsePlayUrl.js" to attempt transforming the URL)
- (void)scene:(UIScene *)scene openURLContexts:(NSSet<UIOpenURLContext *> *)URLContexts
{
    UIOpenURLContext *openURLContext = URLContexts.anyObject;
    if (! openURLContext) {
        return;
    }
    NSURL *URL = openURLContext.URL;
    
    AnalyticsSource analyticsSource = ([URL.scheme isEqualToString:@"http"] || [URL.scheme isEqualToString:@"https"]) ? AnalyticsSourceDeepLink : AnalyticsSourceSchemeURL;
    
    NSArray<DeeplinkAction> *supportedActions = @[ DeeplinkActionMedia, DeeplinkActionShow, DeeplinkActionTopic, DeeplinkActionHome,
                                                   DeeplinkActionAZ, DeeplinkActionByDate, DeeplinkActionSection, DeeplinkActionSearch, DeeplinkActionLink ];
    
    NSURLComponents *URLComponents = [NSURLComponents componentsWithURL:URL resolvingAgainstBaseURL:YES];
    if (! [supportedActions containsObject:URLComponents.host.lowercaseString]) {
        AppDelegate *appDelegate = (AppDelegate *)UIApplication.sharedApplication;
        NSURL *deepLinkURL = [appDelegate.deepLinkService schemeURLFromWebURL:URL];
        if (deepLinkURL) {
            URLComponents = [NSURLComponents componentsWithURL:deepLinkURL resolvingAgainstBaseURL:YES];
        }
    }
    
    if ([supportedActions containsObject:URLComponents.host.lowercaseString]) {
        DeeplinkAction action = URLComponents.host.lowercaseString;
        
#if defined(DEBUG) || defined(NIGHTLY) || defined(BETA)
        NSString *server = [self valueFromURLComponents:URLComponents withParameterName:@"server"];
        if (server) {
            NSURL *serviceURL = ApplicationSettingServiceURLForKey(server);
            if (serviceURL && ! [serviceURL isEqual:ApplicationSettingServiceURL()]) {
                ApplicationSettingSetServiceURL(serviceURL);
                
                [Banner showWithStyle:BannerStyleInfo
                              message:[NSString stringWithFormat:NSLocalizedString(@"Server changed to '%@'", @"Notification message when the server URL changed due to a scheme URL."), ApplicationSettingServiceNameForKey(server)]
                                image:[UIImage imageNamed:@"settings"]
                               sticky:NO
                     inViewController:nil];
            }
        }
#endif
        
        NSString *mediaURN = URLComponents.path.lastPathComponent;
        if ([action isEqualToString:DeeplinkActionMedia] && mediaURN) {
            NSString *channelUid = [self valueFromURLComponents:URLComponents withParameterName:@"channel_id"];
            NSInteger startTime = [[self valueFromURLComponents:URLComponents withParameterName:@"start_time"] integerValue];
            [self openMediaWithURN:mediaURN startTime:startTime channelUid:channelUid fromPushNotification:NO completionBlock:^{
                SRGAnalyticsHiddenEventLabels *labels = [[SRGAnalyticsHiddenEventLabels alloc] init];
                labels.source = analyticsSource;
                labels.type = AnalyticsTypeActionPlayMedia;
                labels.value = mediaURN;
                labels.extraValue1 = openURLContext.options.sourceApplication;
                [SRGAnalyticsTracker.sharedTracker trackHiddenEventWithName:AnalyticsTitleOpenURL labels:labels];
            }];
            return;
        }
        
        NSString *showURN = URLComponents.path.lastPathComponent;
        if ([action isEqualToString:DeeplinkActionShow] && showURN) {
            NSString *channelUid = [self valueFromURLComponents:URLComponents withParameterName:@"channel_id"];
            [self openShowWithURN:showURN channelUid:channelUid fromPushNotification:NO completionBlock:^{
                SRGAnalyticsHiddenEventLabels *labels = [[SRGAnalyticsHiddenEventLabels alloc] init];
                labels.source = analyticsSource;
                labels.type = AnalyticsTypeActionDisplayShow;
                labels.value = showURN;
                labels.extraValue1 = openURLContext.options.sourceApplication;
                [SRGAnalyticsTracker.sharedTracker trackHiddenEventWithName:AnalyticsTitleOpenURL labels:labels];
            }];
            return;
        }
        
        NSString *topicURN = URLComponents.path.lastPathComponent;
        if ([action isEqualToString:DeeplinkActionTopic] && topicURN) {
            [self openTopicWithURN:topicURN completionBlock:^{
                SRGAnalyticsHiddenEventLabels *labels = [[SRGAnalyticsHiddenEventLabels alloc] init];
                labels.source = analyticsSource;
                labels.type = AnalyticsTypeActionDisplayPage;
                labels.value = topicURN;
                labels.extraValue1 = openURLContext.options.sourceApplication;
                [SRGAnalyticsTracker.sharedTracker trackHiddenEventWithName:AnalyticsTitleOpenURL labels:labels];
            }];
            return;
        }
        
        NSArray<DeeplinkAction> *pageActions = @[ DeeplinkActionHome, DeeplinkActionAZ, DeeplinkActionByDate, DeeplinkActionSearch ];
        if ([pageActions containsObject:action]) {
            NSString *channelUid = [self valueFromURLComponents:URLComponents withParameterName:@"channel_id"];
            [self openPageWithAction:action channelUid:channelUid URLComponents:URLComponents completionBlock:^{
                SRGAnalyticsHiddenEventLabels *labels = [[SRGAnalyticsHiddenEventLabels alloc] init];
                labels.source = analyticsSource;
                labels.type = AnalyticsTypeActionDisplayPage;
                labels.value = action;
                labels.extraValue1 = openURLContext.options.sourceApplication;
                [SRGAnalyticsTracker.sharedTracker trackHiddenEventWithName:AnalyticsTitleOpenURL labels:labels];
            }];
            return;
        }
        
        NSString *sectionUid = URLComponents.path.lastPathComponent;
        if ([action isEqualToString:DeeplinkActionSection] && sectionUid) {
            [self openSectionWithUid:sectionUid completionBlock:^{
                SRGAnalyticsHiddenEventLabels *labels = [[SRGAnalyticsHiddenEventLabels alloc] init];
                labels.source = analyticsSource;
                labels.type = AnalyticsTypeActionDisplayPage;
                labels.value = sectionUid;
                labels.extraValue1 = openURLContext.options.sourceApplication;
                [SRGAnalyticsTracker.sharedTracker trackHiddenEventWithName:AnalyticsTitleOpenURL labels:labels];
            }];
            return;
        }
        
        NSString *URLString = [self valueFromURLComponents:URLComponents withParameterName:@"url"];
        NSURL *URL = URLString ? [NSURL URLWithString:URLString] : nil;
        if ([action isEqualToString:DeeplinkActionLink] && URL) {
            [UIApplication.sharedApplication play_openURL:URL withCompletionHandler:^(BOOL success) {
                SRGAnalyticsHiddenEventLabels *labels = [[SRGAnalyticsHiddenEventLabels alloc] init];
                labels.source = analyticsSource;
                labels.type = AnalyticsTypeActionDisplayURL;
                labels.value = URLString;
                labels.extraValue1 = openURLContext.options.sourceApplication;
                [SRGAnalyticsTracker.sharedTracker trackHiddenEventWithName:AnalyticsTitleOpenURL labels:labels];
            }];
            return;
        }
        
        SRGAnalyticsHiddenEventLabels *labels = [[SRGAnalyticsHiddenEventLabels alloc] init];
        labels.source = analyticsSource;
        labels.type = AnalyticsTypeActionOpenPlayApp;
        labels.extraValue1 = openURLContext.options.sourceApplication;
        [SRGAnalyticsTracker.sharedTracker trackHiddenEventWithName:AnalyticsTitleOpenURL labels:labels];
        return;
    }
}

#pragma mark Notifications

- (void)settingDidChange:(NSNotification *)notification
{
    NSNumber *presenterModeEnabled = notification.userInfo[PlaySRGSettingPresenterModeEnabled];
    if (presenterModeEnabled) {
        [self setPresenterModeEnabled:presenterModeEnabled.boolValue];
    }
}

#pragma mark Custom URL scheme support

- (NSString *)valueFromURLComponents:(NSURLComponents *)URLComponents withParameterName:(NSString *)parameterName
{
    NSParameterAssert(URLComponents);
    NSParameterAssert(parameterName);
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == %@", @keypath(NSURLQueryItem.new, name), parameterName];
    NSURLQueryItem *queryItem = [URLComponents.queryItems filteredArrayUsingPredicate:predicate].firstObject;
    if (! queryItem) {
        return nil;
    }
    
    return queryItem.value;
}

- (void)openMediaWithURN:(NSString *)mediaURN startTime:(NSInteger)startTime channelUid:(NSString *)channelUid fromPushNotification:(BOOL)fromPushNotification completionBlock:(void (^)(void))completionBlock
{
    NSParameterAssert(mediaURN);
    
    RadioChannel *radioChannel = [ApplicationConfiguration.sharedApplicationConfiguration radioChannelForUid:channelUid];
    ApplicationSectionInfo *applicationSectionInfo = [ApplicationSectionInfo applicationSectionInfoWithApplicationSection:ApplicationSectionOverview radioChannel:radioChannel options:nil];
    
    [self resetWithApplicationSectionInfo:applicationSectionInfo completionBlock:^{
        CMTime time = (startTime > 0) ? CMTimeMakeWithSeconds(startTime, NSEC_PER_SEC) : kCMTimeZero;
        [self playURN:mediaURN media:nil atPosition:[SRGPosition positionAtTime:time] fromPushNotification:fromPushNotification completion:nil];
        completionBlock ? completionBlock() : nil;
    }];
}

- (void)openShowWithURN:(NSString *)showURN channelUid:(NSString *)channelUid fromPushNotification:(BOOL)fromPushNotification completionBlock:(void (^)(void))completionBlock
{
    NSParameterAssert(showURN);
    
    RadioChannel *radioChannel = [ApplicationConfiguration.sharedApplicationConfiguration radioChannelForUid:channelUid];
    ApplicationSectionInfo *applicationSectionInfo = [ApplicationSectionInfo applicationSectionInfoWithApplicationSection:ApplicationSectionOverview radioChannel:radioChannel options:nil];
    
    [self resetWithApplicationSectionInfo:applicationSectionInfo completionBlock:^{
        [self openShowURN:showURN show:nil fromPushNotification:fromPushNotification];
        completionBlock ? completionBlock() : nil;
    }];
}

- (void)openShowListAtIndex:(NSString *)index withChannelUid:(NSString *)channelUid completionBlock:(void (^)(void))completionBlock
{
    NSMutableDictionary *options = [NSMutableDictionary dictionary];
    options[ApplicationSectionOptionShowAZIndexKey] = index;
    
    RadioChannel *radioChannel = [ApplicationConfiguration.sharedApplicationConfiguration radioChannelForUid:channelUid];
    ApplicationSectionInfo *applicationSectionInfo = [ApplicationSectionInfo applicationSectionInfoWithApplicationSection:ApplicationSectionShowAZ radioChannel:radioChannel options:options.copy];
    [self resetWithApplicationSectionInfo:applicationSectionInfo completionBlock:completionBlock];
}

- (void)openCalendarAtDate:(NSDate *)date withChannelUid:(NSString *)channelUid completionBlock:(void (^)(void))completionBlock
{
    NSMutableDictionary *options = [NSMutableDictionary dictionary];
    options[ApplicationSectionOptionShowByDateDateKey] = date;
    
    RadioChannel *radioChannel = [ApplicationConfiguration.sharedApplicationConfiguration radioChannelForUid:channelUid];
    ApplicationSectionInfo *applicationSectionInfo = [ApplicationSectionInfo applicationSectionInfoWithApplicationSection:ApplicationSectionShowByDate radioChannel:radioChannel options:options.copy];
    [self resetWithApplicationSectionInfo:applicationSectionInfo completionBlock:completionBlock];
}

- (void)openSearchWithQuery:(NSString *)query mediaType:(SRGMediaType)mediaType completionBlock:(void (^)(void))completionBlock
{
    NSMutableDictionary *options = [NSMutableDictionary dictionary];
    options[ApplicationSectionOptionSearchMediaTypeOptionKey] = @(mediaType);
    options[ApplicationSectionOptionSearchQueryKey] = query;
    
    ApplicationSectionInfo *applicationSectionInfo = [ApplicationSectionInfo applicationSectionInfoWithApplicationSection:ApplicationSectionSearch radioChannel:nil options:options.copy];
    [self resetWithApplicationSectionInfo:applicationSectionInfo completionBlock:completionBlock];
}

- (void)openHomeWithChannelUid:(NSString *)channelUid completionBlock:(void (^)(void))completionBlock
{
    RadioChannel *radioChannel = [ApplicationConfiguration.sharedApplicationConfiguration radioChannelForUid:channelUid];
    ApplicationSectionInfo *applicationSectionInfo = [ApplicationSectionInfo applicationSectionInfoWithApplicationSection:ApplicationSectionOverview radioChannel:radioChannel];
    [self resetWithApplicationSectionInfo:applicationSectionInfo completionBlock:completionBlock];
}

- (void)openPageWithAction:(DeeplinkAction)action channelUid:(NSString *)channelUid URLComponents:(NSURLComponents *)URLComponents completionBlock:(void (^)(void))completionBlock
{
    NSParameterAssert(action);
    
    if ([action isEqualToString:DeeplinkActionAZ]) {
        NSString *index = [self valueFromURLComponents:URLComponents withParameterName:@"index"];
        [self openShowListAtIndex:index withChannelUid:channelUid completionBlock:completionBlock];
    }
    else if ([action isEqualToString:DeeplinkActionByDate]) {
        NSString *dateString = [self valueFromURLComponents:URLComponents withParameterName:@"date"];
        NSDate *date = dateString ? [NSDateFormatter.play_URLOptionDateFormatter dateFromString:dateString] : nil;
        [self openCalendarAtDate:date withChannelUid:channelUid completionBlock:completionBlock];
    }
    else if ([action isEqualToString:DeeplinkActionSearch]) {
        NSString *query = [self valueFromURLComponents:URLComponents withParameterName:@"query"];
        
        static NSDictionary<NSString *, NSNumber *> *s_mediaTypes;
        static dispatch_once_t s_onceToken;
        dispatch_once(&s_onceToken, ^{
            s_mediaTypes = @{ @"video" : @(SRGMediaTypeVideo),
                              @"audio" : @(SRGMediaTypeAudio) };
        });
        
        NSString *mediaTypeName = [self valueFromURLComponents:URLComponents withParameterName:@"media_type"];
        SRGMediaType mediaType = s_mediaTypes[mediaTypeName].integerValue;
        
        [self openSearchWithQuery:query mediaType:mediaType completionBlock:completionBlock];
    }
    else if ([action isEqualToString:DeeplinkActionHome]) {
        [self openHomeWithChannelUid:channelUid completionBlock:completionBlock];
    }
}

- (void)openTopicWithURN:(NSString *)topicURN completionBlock:(void (^)(void))completionBlock
{
    NSParameterAssert(topicURN);
    
    ApplicationSectionInfo *applicationSectionInfo = [ApplicationSectionInfo applicationSectionInfoWithApplicationSection:ApplicationSectionOverview radioChannel:nil];
    [self resetWithApplicationSectionInfo:applicationSectionInfo completionBlock:^{
        [self openTopicURN:topicURN];
        completionBlock ? completionBlock() : nil;
    }];
}

- (void)openSectionWithUid:(NSString *)sectionUid completionBlock:(void (^)(void))completionBlock
{
    NSParameterAssert(sectionUid);
    
    ApplicationSectionInfo *applicationSectionInfo = [ApplicationSectionInfo applicationSectionInfoWithApplicationSection:ApplicationSectionOverview radioChannel:nil];
    [self resetWithApplicationSectionInfo:applicationSectionInfo completionBlock:^{
        [self openSectionUid:sectionUid];
        completionBlock ? completionBlock() : nil;
    }];
}

#pragma mark Handoff

- (void)scene:(UIScene *)scene continueUserActivity:(NSUserActivity *)userActivity
{
    if ([userActivity.activityType isEqualToString:[NSBundle.mainBundle.bundleIdentifier stringByAppendingString:@".playing"]]) {
        NSString *mediaURN = userActivity.userInfo[@"URNString"];
        if (mediaURN) {
            SRGMedia *media = [NSKeyedUnarchiver unarchivedObjectOfClass:SRGMedia.class fromData:userActivity.userInfo[@"SRGMediaData"] error:NULL];
            NSNumber *position = [userActivity.userInfo[@"position"] isKindOfClass:NSNumber.class] ? userActivity.userInfo[@"position"] : nil;
            [self playURN:mediaURN media:media atPosition:[SRGPosition positionAtTimeInSeconds:position.integerValue] fromPushNotification:NO completion:nil];
            
            SRGAnalyticsHiddenEventLabels *labels = [[SRGAnalyticsHiddenEventLabels alloc] init];
            labels.source = AnalyticsSourceHandoff;
            labels.type = AnalyticsTypeActionPlayMedia;
            labels.value = mediaURN;
            [SRGAnalyticsTracker.sharedTracker trackHiddenEventWithName:AnalyticsTitleUserActivity labels:labels];
        }
        else {
            NSError *error = [NSError errorWithDomain:PlayErrorDomain
                                                 code:PlayErrorCodeNotFound
                                             userInfo:@{ NSLocalizedDescriptionKey : NSLocalizedString(@"The media cannot be opened.", @"Error message when a media cannot be opened via Handoff") }];
            [Banner showError:error inViewController:nil];
        }
    }
    else if ([userActivity.activityType isEqualToString:[NSBundle.mainBundle.bundleIdentifier stringByAppendingString:@".displaying"]]) {
        NSString *showURN = userActivity.userInfo[@"URNString"];
        if (showURN) {
            SRGShow *show = [NSKeyedUnarchiver unarchivedObjectOfClass:SRGShow.class fromData:userActivity.userInfo[@"SRGShowData"] error:NULL];
            
            RadioChannel *radioChannel = [ApplicationConfiguration.sharedApplicationConfiguration radioChannelForUid:show.primaryChannelUid];
            ApplicationSectionInfo *applicationSectionInfo = [ApplicationSectionInfo applicationSectionInfoWithApplicationSection:ApplicationSectionOverview radioChannel:radioChannel options:nil];
            
            [self resetWithApplicationSectionInfo:applicationSectionInfo completionBlock:^{
                [self openShowURN:showURN show:show fromPushNotification:NO];
            }];
            
            SRGAnalyticsHiddenEventLabels *labels = [[SRGAnalyticsHiddenEventLabels alloc] init];
            labels.source = AnalyticsSourceHandoff;
            labels.type = AnalyticsTypeActionDisplayShow;
            labels.value = showURN;
            [SRGAnalyticsTracker.sharedTracker trackHiddenEventWithName:AnalyticsTitleUserActivity labels:labels];
        }
        else {
            NSError *error = [NSError errorWithDomain:PlayErrorDomain
                                                 code:PlayErrorCodeNotFound
                                             userInfo:@{ NSLocalizedDescriptionKey : NSLocalizedString(@"The show cannot be opened.", @"Error message when a show cannot be opened via Handoff") }];
            [Banner showError:error inViewController:nil];
        }
    }
    else if ([userActivity.activityType isEqualToString:NSUserActivityTypeBrowsingWeb]) {
        return [UIApplication.sharedApplication openURL:userActivity.webpageURL options:@{} completionHandler:nil];
    }
}

- (void)scene:(UIScene *)scene didFailToContinueUserActivityWithType:(NSString *)userActivityType error:(NSError *)error
{
    PlayLogWarning(@"application", @"Could not retrieve user activity for %@. Reason: %@", userActivityType, error);
    [Banner showError:error inViewController:nil];
}

#pragma mark Actions

- (BOOL)handleShortcutItem:(UIApplicationShortcutItem *)shortcutItem
{
    ApplicationSectionInfo *applicationSectionInfo = nil;
    SRGAnalyticsHiddenEventLabels *labels = [[SRGAnalyticsHiddenEventLabels alloc] init];
    
    if ([shortcutItem.type isEqualToString:@"favorites"]) {
        applicationSectionInfo = [ApplicationSectionInfo applicationSectionInfoWithApplicationSection:ApplicationSectionFavorites radioChannel:nil];
        labels.type = AnalyticsTypeActionFavorites;
    }
    else if ([shortcutItem.type isEqualToString:@"downloads"]) {
        applicationSectionInfo = [ApplicationSectionInfo applicationSectionInfoWithApplicationSection:ApplicationSectionDownloads radioChannel:nil];
        labels.type = AnalyticsTypeActionDownloads;
    }
    else if ([shortcutItem.type isEqualToString:@"history"]) {
        applicationSectionInfo = [ApplicationSectionInfo applicationSectionInfoWithApplicationSection:ApplicationSectionHistory radioChannel:nil];
        labels.type = AnalyticsTypeActionHistory;
    }
    else if ([shortcutItem.type isEqualToString:@"search"]) {
        applicationSectionInfo = [ApplicationSectionInfo applicationSectionInfoWithApplicationSection:ApplicationSectionSearch radioChannel:nil];
        labels.type = AnalyticsTypeActionSearch;
    }
    else {
        return NO;
    }
    
    [SRGAnalyticsTracker.sharedTracker trackHiddenEventWithName:AnalyticsTitleQuickActions labels:labels];
    
    [self resetWithApplicationSectionInfo:applicationSectionInfo completionBlock:nil];
    return YES;
}

#pragma mark Controlling the app

// Reset the app view controller hierachy to display the specified application section, executing the provided completion block when done.
- (void)resetWithApplicationSectionInfo:(ApplicationSectionInfo *)applicationSectionInfo completionBlock:(void (^)(void))completionBlock
{
    void (^openApplicationSectionInfo)(void) = ^{
        [self.rootTabBarController openApplicationSectionInfo:applicationSectionInfo];
        completionBlock ? completionBlock() : nil;
    };
    
    // When dismissing a view controller with a transitioning delegate while the app is in the background, with animated = NO, there
    // is a bug leading to an incorrect final state. The bug does not occur if animated = YES, but the transition is visible. To get
    // a perfect result, we completely disable animations during the transition
    if (self.rootTabBarController.presentedViewController) {
        [UIView setAnimationsEnabled:NO];
        [self.rootTabBarController dismissViewControllerAnimated:YES completion:^{
            [UIView setAnimationsEnabled:YES];
            openApplicationSectionInfo();
        }];
    }
    else {
        openApplicationSectionInfo();
    }
}

- (void)playURN:(NSString *)mediaURN media:(SRGMedia *)media atPosition:(SRGPosition *)position fromPushNotification:(BOOL)fromPushNotification completion:(void (^)(PlayerType))completion
{
    if (media) {
        [self.rootTabBarController play_presentMediaPlayerWithMedia:media position:position airPlaySuggestions:YES fromPushNotification:fromPushNotification animated:YES completion:completion];
    }
    else {
        [[SRGDataProvider.currentDataProvider mediaWithURN:mediaURN completionBlock:^(SRGMedia * _Nullable media, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
            if (media) {
                [self.rootTabBarController play_presentMediaPlayerWithMedia:media position:position airPlaySuggestions:YES fromPushNotification:fromPushNotification animated:YES completion:completion];
            }
            else {
                NSError *error = [NSError errorWithDomain:PlayErrorDomain
                                                     code:PlayErrorCodeNotFound
                                                 userInfo:@{ NSLocalizedDescriptionKey : NSLocalizedString(@"The media cannot be opened.", @"Error message when a media cannot be opened via Handoff, deep linking or a push notification") }];
                [Banner showError:error inViewController:nil];
            }
        }] resume];
    }
}

- (void)openShowURN:(NSString *)showURN show:(SRGShow *)show fromPushNotification:(BOOL)fromPushNotification
{
    if (show) {
        SectionViewController *showViewController = [SectionViewController showViewControllerFor:show fromPushNotification:fromPushNotification];
        [self.rootTabBarController pushViewController:showViewController animated:YES];
    }
    else {
        [[SRGDataProvider.currentDataProvider showWithURN:showURN completionBlock:^(SRGShow * _Nullable show, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
            if (show) {
                SectionViewController *showViewController = [SectionViewController showViewControllerFor:show fromPushNotification:fromPushNotification];
                [self.rootTabBarController pushViewController:showViewController animated:YES];
            }
            else {
                NSError *error = [NSError errorWithDomain:PlayErrorDomain
                                                     code:PlayErrorCodeNotFound
                                                 userInfo:@{ NSLocalizedDescriptionKey : NSLocalizedString(@"The show cannot be opened.", @"Error message when a show cannot be opened via Handoff, deep linking or a push notification") }];
                [Banner showError:error inViewController:nil];
            }
        }] resume];
    }
}

- (void)openTopicURN:(NSString *)topicURN
{
    [[SRGDataProvider.currentDataProvider tvTopicsForVendor:ApplicationConfiguration.sharedApplicationConfiguration.vendor withCompletionBlock:^(NSArray<SRGTopic *> * _Nullable topics, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == %@", @keypath(SRGTopic.new, URN), topicURN];
        SRGTopic *topic = [topics filteredArrayUsingPredicate:predicate].firstObject;
        if (topic) {
            UIViewController *topicViewController = [PageViewController topicViewControllerFor:topic];
            [self.rootTabBarController pushViewController:topicViewController animated:YES];
        }
        else {
            NSError *error = [NSError errorWithDomain:PlayErrorDomain
                                                 code:PlayErrorCodeNotFound
                                             userInfo:@{ NSLocalizedDescriptionKey : NSLocalizedString(@"The page cannot be opened.", @"Error message when a topic cannot be opened via Handoff, deep linking or a push notification") }];
            [Banner showError:error inViewController:nil];
        }
    }] resume];
}

- (void)openSectionUid:(NSString *)sectionUid
{
    [[SRGDataProvider.currentDataProvider contentSectionForVendor:ApplicationConfiguration.sharedApplicationConfiguration.vendor uid:sectionUid published:YES withCompletionBlock:^(SRGContentSection * _Nullable contentSection, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
        if (contentSection) {
            SectionViewController *sectionViewController = [SectionViewController viewControllerForContentSection:contentSection];
            [self.rootTabBarController pushViewController:sectionViewController animated:YES];
        }
        else {
            NSError *error = [NSError errorWithDomain:PlayErrorDomain
                                                 code:PlayErrorCodeNotFound
                                             userInfo:@{ NSLocalizedDescriptionKey : NSLocalizedString(@"The section cannot be opened.", @"Error message when a section cannot be opened via Handoff, deep linking or a push notification") }];
            [Banner showError:error inViewController:nil];
        }
    }] resume];
}

@end
