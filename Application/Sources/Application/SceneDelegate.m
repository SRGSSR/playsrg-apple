//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SceneDelegate.h"

#import "ApplicationConfiguration.h"
#import "ApplicationSettings.h"
#import "ApplicationSettingsConstants.h"
#import "DeepLinkAction.h"
#import "PlayErrors.h"
#import "PlayLogger.h"
#import "PlaySRG-Swift.h"
#import "UIApplication+PlaySRG.h"

@import libextobjc;
@import SRGDataProvider;

static void *s_kvoContext = &s_kvoContext;

@implementation SceneDelegate

#pragma mark Getters and setters

- (TabBarController *)rootTabBarController
{
    return (TabBarController *)self.window.rootViewController;
}

#pragma mark UIWindowSceneDelegate protocol

- (void)scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session options:(UISceneConnectionOptions *)connectionOptions
{
    if (! [scene isKindOfClass:UIWindowScene.class]) {
        return;
    }
    
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(userDefaultsDidChange:)
                                               name:NSUserDefaultsDidChangeNotification
                                             object:nil];
    
    UIWindowScene *windowScene = (UIWindowScene *)scene;
    self.window = [[UIWindow alloc] initWithWindowScene:windowScene];
    self.window.backgroundColor = UIColor.blackColor;
    self.window.accessibilityIgnoresInvertColors = YES;
    
    [self.window makeKeyAndVisible];
    self.window.rootViewController = [[TabBarController alloc] init];
    
    [PresenterMode enable:ApplicationSettingPresenterModeEnabled()];
    
    [self handleShortcutItem:connectionOptions.shortcutItem];
    [self handleURLContexts:connectionOptions.URLContexts];
    [self handleUserActivities:connectionOptions.userActivities];
    
#if defined(DEBUG) || defined(NIGHTLY) || defined(BETA)
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    [defaults addObserver:self forKeyPath:PlaySRGSettingServiceEnvironment options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:s_kvoContext];
    [defaults addObserver:self forKeyPath:PlaySRGSettingUserLocation options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:s_kvoContext];
    [defaults addObserver:self forKeyPath:PlaySRGSettingProxyDetection options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:s_kvoContext];
    [defaults addObserver:self forKeyPath:PlaySRGSettingPosterImages options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:s_kvoContext];
    [defaults addObserver:self forKeyPath:PlaySRGSettingPodcastImages options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:s_kvoContext];
    [defaults addObserver:self forKeyPath:PlaySRGSettingAudioHomepageOption options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:s_kvoContext];
#endif
}

- (void)sceneDidDisconnect:(UIScene *)scene
{
#if defined(DEBUG) || defined(NIGHTLY) || defined(BETA)
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    [defaults removeObserver:self forKeyPath:PlaySRGSettingServiceEnvironment];
    [defaults removeObserver:self forKeyPath:PlaySRGSettingUserLocation];
    [defaults removeObserver:self forKeyPath:PlaySRGSettingProxyDetection];
    [defaults removeObserver:self forKeyPath:PlaySRGSettingPosterImages];
    [defaults removeObserver:self forKeyPath:PlaySRGSettingPodcastImages];
    [defaults removeObserver:self forKeyPath:PlaySRGSettingAudioHomepageOption];
#endif
}

- (void)windowScene:(UIWindowScene *)windowScene performActionForShortcutItem:(UIApplicationShortcutItem *)shortcutItem completionHandler:(void (^)(BOOL))completionHandler
{
    BOOL handledShortcutItem = [self handleShortcutItem:shortcutItem];
    completionHandler(handledShortcutItem);
}

- (void)scene:(UIScene *)scene openURLContexts:(NSSet<UIOpenURLContext *> *)URLContexts
{
    [self handleURLContexts:URLContexts];
}

#pragma mark Custom scheme urls

- (void)handleURLContexts:(NSSet<UIOpenURLContext *> *)URLContexts
{
    // FIXME: Works as long as only one context is received
    UIOpenURLContext *URLContext = URLContexts.anyObject;
    if (! URLContext) {
        return;
    }
    
    [self handleDeepLinkAction:[DeepLinkAction actionFromURLContext:URLContext]];
}

- (void)handleDeepLinkAction:(DeepLinkAction *)action
{
#if defined(DEBUG) || defined(NIGHTLY) || defined(BETA)
    NSString *serviceIdentifier = [action parameterWithName:@"server"];
    if (serviceIdentifier) {
        if (! [serviceIdentifier isEqual:ApplicationSettingServiceIdentifier()]) {
            ApplicationSettingSetServiceIdentifier(serviceIdentifier);
            
            NSString *serviceName = [ServiceObjC nameForEnvironment:serviceIdentifier];
            [Banner showWith:BannerStyleInfo
                     message:[NSString stringWithFormat:NSLocalizedString(@"Server changed to '%@'", @"Notification message when the server URL changed due to a custom URL."), serviceName]
                       image:[UIImage imageNamed:@"settings"]
                      sticky:NO];
        }
    }
#endif
    
    if ([action.type isEqualToString:DeepLinkTypeMedia]) {
        NSString *channelUid = [action parameterWithName:@"channel_id"];
        NSInteger startTime = [action parameterWithName:@"start_time"].integerValue;
        [self openMediaWithURN:action.identifier startTime:startTime channelUid:channelUid fromPushNotification:NO completionBlock:^{
            [action.analyticsEvent send];
        }];
    }
    else if ([action.type isEqualToString:DeepLinkTypeShow]) {
        NSString *channelUid = [action parameterWithName:@"channel_id"];
        [self openShowWithURN:action.identifier channelUid:channelUid fromPushNotification:NO completionBlock:^{
            [action.analyticsEvent send];
        }];
    }
    else if ([action.type isEqualToString:DeepLinkTypeTopic]) {
        [self openTopicWithURN:action.identifier completionBlock:^{
            [action.analyticsEvent send];
        }];
    }
    else if ([action.type isEqualToString:DeepLinkTypePage] || [action.type isEqualToString:DeepLinkTypeMicroPage]) {
        [self openPageWithUid:action.identifier completionBlock:^{
            [action.analyticsEvent send];
        }];
    }
    else if ([action.type isEqualToString:DeepLinkTypeHome]) {
        NSString *channelUid = [action parameterWithName:@"channel_id"];
        [self openHomeWithChannelUid:channelUid completionBlock:^{
            [action.analyticsEvent send];
        }];
    }
    else if ([action.type isEqualToString:DeepLinkTypeAZ]) {
        NSString *index = [action parameterWithName:@"index"];
        NSString *channelUid = [action parameterWithName:@"channel_id"];
        [self openShowListAtIndex:index withChannelUid:channelUid completionBlock:^{
            [action.analyticsEvent send];
        }];
    }
    else if ([action.type isEqualToString:DeepLinkTypeByDate]) {
        NSString *dateString = [action parameterWithName:@"date"];
        NSDate *date = dateString ? [NSDateFormatter.play_iso8601CalendarDate dateFromString:dateString] : nil;
        NSString *channelUid = [action parameterWithName:@"channel_id"];
        [self openCalendarAtDate:date withChannelUid:channelUid completionBlock:^{
            [action.analyticsEvent send];
        }];
    }
    else if ([action.type isEqualToString:DeepLinkTypeSection]) {
        [self openSectionWithUid:action.identifier completionBlock:^{
            [action.analyticsEvent send];
        }];
    }
    else if ([action.type isEqualToString:DeepLinkTypeSearch]) {
        NSString *query = [action parameterWithName:@"query"];
        
        static NSDictionary<NSString *, NSNumber *> *s_mediaTypes;
        static dispatch_once_t s_onceToken;
        dispatch_once(&s_onceToken, ^{
            s_mediaTypes = @{ @"video" : @(SRGMediaTypeVideo),
                              @"audio" : @(SRGMediaTypeAudio) };
        });
        
        NSString *mediaTypeName = [action parameterWithName:@"media_type"];
        SRGMediaType mediaType = s_mediaTypes[mediaTypeName].integerValue;
        
        [self openSearchWithQuery:query mediaType:mediaType completionBlock:^{
            [action.analyticsEvent send];
        }];
    }
    else if ([action.type isEqualToString:DeepLinkTypeLivestreams]) {
        [self openLivestreamsWithCompletionBlock:^{
            [action.analyticsEvent send];
        }];
    }
    else if ([action.type isEqualToString:DeepLinkTypeLink]) {
        NSURL *URL = [NSURL URLWithString:action.identifier];
        if (URL) {
            [UIApplication.sharedApplication play_openURL:URL withCompletionHandler:^(BOOL success) {
                [action.analyticsEvent send];
            }];
        }
        else {
            [action.analyticsEvent send];
        }
    }
    else {
        [action.analyticsEvent send];
    }
}

#pragma mark Notifications

- (void)userDefaultsDidChange:(NSNotification *)notification
{
    [PresenterMode enable:ApplicationSettingPresenterModeEnabled()];
}

#pragma mark User interface changes

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
    RadioChannel *radioChannel = [ApplicationConfiguration.sharedApplicationConfiguration radioHomepageChannelForUid:channelUid];
    ApplicationSectionInfo *applicationSectionInfo = [ApplicationSectionInfo applicationSectionInfoWithApplicationSection:ApplicationSectionOverview radioChannel:radioChannel];
    [self resetWithApplicationSectionInfo:applicationSectionInfo completionBlock:completionBlock];
}

- (void)openLivestreamsWithCompletionBlock:(void (^)(void))completionBlock
{
    ApplicationSectionInfo *applicationSectionInfo = [ApplicationSectionInfo applicationSectionInfoWithApplicationSection:ApplicationSectionLive radioChannel:nil];
    [self resetWithApplicationSectionInfo:applicationSectionInfo completionBlock:completionBlock];
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

- (void)openPageWithUid:(NSString *)pageUid completionBlock:(void (^)(void))completionBlock
{
    NSParameterAssert(pageUid);
    
    ApplicationSectionInfo *applicationSectionInfo = [ApplicationSectionInfo applicationSectionInfoWithApplicationSection:ApplicationSectionOverview radioChannel:nil];
    [self resetWithApplicationSectionInfo:applicationSectionInfo completionBlock:^{
        [self openPageUid:pageUid];
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

#pragma mark Handoff and universal links

- (void)scene:(UIScene *)scene continueUserActivity:(NSUserActivity *)userActivity
{
    [self handleUserActivity:userActivity];
}

- (void)scene:(UIScene *)scene didFailToContinueUserActivityWithType:(NSString *)userActivityType error:(NSError *)error
{
    PlayLogWarning(@"application", @"Could not retrieve user activity for %@. Reason: %@", userActivityType, error);
    [Banner showError:error];
}

- (void)handleUserActivities:(NSSet<NSUserActivity *> *)userActivities
{
    // FIXME: Works as long as only one activity is received
    NSUserActivity *userActivity = userActivities.anyObject;
    if (! userActivity) {
        return;
    }
    
    [self handleUserActivity:userActivity];
}

- (void)handleUserActivity:(NSUserActivity *)userActivity
{
    if ([userActivity.activityType isEqualToString:[NSBundle.mainBundle.bundleIdentifier stringByAppendingString:@".playing"]]) {
        NSString *mediaURN = userActivity.userInfo[@"URNString"];
        if (mediaURN) {
            SRGMedia *media = [NSKeyedUnarchiver unarchivedObjectOfClass:SRGMedia.class fromData:userActivity.userInfo[@"SRGMediaData"] error:NULL];
            NSNumber *position = [userActivity.userInfo[@"position"] isKindOfClass:NSNumber.class] ? userActivity.userInfo[@"position"] : nil;
            [self playURN:mediaURN media:media atPosition:[SRGPosition positionAtTimeInSeconds:position.integerValue] fromPushNotification:NO completion:nil];
            
            [[AnalyticsEventObjC userActivityWithAction:AnalyticsUserActivityActionPlayMedia urn:mediaURN] send];
        }
        else {
            NSError *error = [NSError errorWithDomain:PlayErrorDomain
                                                 code:PlayErrorCodeNotFound
                                             userInfo:@{ NSLocalizedDescriptionKey : NSLocalizedString(@"The media cannot be opened.", @"Error message when a media cannot be opened via Handoff") }];
            [Banner showError:error];
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
            
            [[AnalyticsEventObjC userActivityWithAction:AnalyticsUserActivityActionDisplayShow urn:showURN] send];
        }
        else {
            NSError *error = [NSError errorWithDomain:PlayErrorDomain
                                                 code:PlayErrorCodeNotFound
                                             userInfo:@{ NSLocalizedDescriptionKey : NSLocalizedString(@"The show cannot be opened.", @"Error message when a show cannot be opened via Handoff") }];
            [Banner showError:error];
        }
    }
    else if ([userActivity.activityType isEqualToString:NSUserActivityTypeBrowsingWeb]) {
        [self handleDeepLinkAction:[DeepLinkAction actionFromUniversalLinkURL:userActivity.webpageURL]];
    }
}

#pragma mark Actions

- (BOOL)handleShortcutItem:(UIApplicationShortcutItem *)shortcutItem
{
    if (! shortcutItem) {
        return NO;
    }
    
    ApplicationSectionInfo *applicationSectionInfo = nil;
    if ([shortcutItem.type isEqualToString:@"favorites"]) {
        applicationSectionInfo = [ApplicationSectionInfo applicationSectionInfoWithApplicationSection:ApplicationSectionFavorites radioChannel:nil];
        [[AnalyticsEventObjC shortcutItemWithAction:AnalyticsShortcutItemActionFavorites] send];
    }
    else if ([shortcutItem.type isEqualToString:@"downloads"]) {
        applicationSectionInfo = [ApplicationSectionInfo applicationSectionInfoWithApplicationSection:ApplicationSectionDownloads radioChannel:nil];
        [[AnalyticsEventObjC shortcutItemWithAction:AnalyticsShortcutItemActionDownloads] send];
    }
    else if ([shortcutItem.type isEqualToString:@"history"]) {
        applicationSectionInfo = [ApplicationSectionInfo applicationSectionInfoWithApplicationSection:ApplicationSectionHistory radioChannel:nil];
        [[AnalyticsEventObjC shortcutItemWithAction:AnalyticsShortcutItemActionHistory] send];
    }
    else if ([shortcutItem.type isEqualToString:@"search"]) {
        applicationSectionInfo = [ApplicationSectionInfo applicationSectionInfoWithApplicationSection:ApplicationSectionSearch radioChannel:nil];
        [[AnalyticsEventObjC shortcutItemWithAction:AnalyticsShortcutItemActionSearch] send];
    }
    else {
        return NO;
    }
    
    [self resetWithApplicationSectionInfo:applicationSectionInfo completionBlock:nil];
    return YES;
}

#pragma mark Controlling the app

// Reset the app view controller hierachy to display the specified application section, executing the provided completion block when done.
- (void)resetWithApplicationSectionInfo:(ApplicationSectionInfo *)applicationSectionInfo completionBlock:(void (^)(void))completionBlock
{
    [UserConsentHelper waitCollectingConsentRetain];
    
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
            [UserConsentHelper waitCollectingConsentRelease];
        }];
    }
    else {
        openApplicationSectionInfo();
        [UserConsentHelper waitCollectingConsentRelease];
    }
}

- (void)playURN:(NSString *)mediaURN media:(SRGMedia *)media atPosition:(SRGPosition *)position fromPushNotification:(BOOL)fromPushNotification completion:(void (^)(PlayerType))completion
{
    [UserConsentHelper waitCollectingConsentRetain];
    if (media) {
        [self.rootTabBarController play_presentMediaPlayerWithMedia:media position:position airPlaySuggestions:YES fromPushNotification:fromPushNotification animated:YES completion:completion];
    }
    else {
        [[SRGDataProvider.currentDataProvider mediaWithURN:mediaURN completionBlock:^(SRGMedia * _Nullable media, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
            if (media) {
                [self.rootTabBarController play_presentMediaPlayerWithMedia:media position:position airPlaySuggestions:YES fromPushNotification:fromPushNotification animated:YES completion:^(PlayerType playerType) {
                    [UserConsentHelper waitCollectingConsentRelease];
                    completion ? completion(playerType) : nil;
                }];
            }
            else {
                NSError *error = [NSError errorWithDomain:PlayErrorDomain
                                                     code:PlayErrorCodeNotFound
                                                 userInfo:@{ NSLocalizedDescriptionKey : NSLocalizedString(@"The media cannot be opened.", @"Error message when a media cannot be opened via Handoff, deep linking or a push notification") }];
                [Banner showError:error];
                [UserConsentHelper waitCollectingConsentRelease];
            }
        }] resume];
    }
}

- (void)openShowURN:(NSString *)showURN show:(SRGShow *)show fromPushNotification:(BOOL)fromPushNotification
{
    [UserConsentHelper waitCollectingConsentRetain];
    if (show) {
        PageViewController *pageViewController = [PageViewController showViewControllerFor:show fromPushNotification:fromPushNotification];
        [self.rootTabBarController pushViewController:pageViewController animated:YES];
        [UserConsentHelper waitCollectingConsentRelease];
    }
    else {
        [[SRGDataProvider.currentDataProvider showWithURN:showURN completionBlock:^(SRGShow * _Nullable show, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
            if (show) {
                PageViewController *pageViewController = [PageViewController showViewControllerFor:show fromPushNotification:fromPushNotification];
                [self.rootTabBarController pushViewController:pageViewController animated:YES];
            }
            else {
                NSError *error = [NSError errorWithDomain:PlayErrorDomain
                                                     code:PlayErrorCodeNotFound
                                                 userInfo:@{ NSLocalizedDescriptionKey : NSLocalizedString(@"The show cannot be opened.", @"Error message when a show cannot be opened via Handoff, deep linking or a push notification") }];
                [Banner showError:error];
            }
            [UserConsentHelper waitCollectingConsentRelease];
        }] resume];
    }
}

- (void)openTopicURN:(NSString *)topicURN
{
    [UserConsentHelper waitCollectingConsentRetain];
    [[SRGDataProvider.currentDataProvider tvTopicsForVendor:ApplicationConfiguration.sharedApplicationConfiguration.vendor withCompletionBlock:^(NSArray<SRGTopic *> * _Nullable topics, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == %@", @keypath(SRGTopic.new, URN), topicURN];
        SRGTopic *topic = [topics filteredArrayUsingPredicate:predicate].firstObject;
        if (topic) {
            PageViewController *pageViewController = [PageViewController topicViewControllerFor:topic];
            [self.rootTabBarController pushViewController:pageViewController animated:YES];
        }
        else {
            NSError *error = [NSError errorWithDomain:PlayErrorDomain
                                                 code:PlayErrorCodeNotFound
                                             userInfo:@{ NSLocalizedDescriptionKey : NSLocalizedString(@"The page cannot be opened.", @"Error message when a topic cannot be opened via Handoff, deep linking or a push notification") }];
            [Banner showError:error];
        }
        [UserConsentHelper waitCollectingConsentRelease];
    }] resume];
}

- (void)openPageUid:(NSString *)pageUid
{
    [UserConsentHelper waitCollectingConsentRetain];
    [[SRGDataProvider.currentDataProvider contentPageForVendor:ApplicationConfiguration.sharedApplicationConfiguration.vendor uid:pageUid published:YES atDate:nil withCompletionBlock:^(SRGContentPage * _Nullable contentPage, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
        if (contentPage) {
            PageViewController *pageViewController = [PageViewController pageViewControllerFor:contentPage];
            [self.rootTabBarController pushViewController:pageViewController animated:YES];
        }
        else {
            NSError *error = [NSError errorWithDomain:PlayErrorDomain
                                                 code:PlayErrorCodeNotFound
                                             userInfo:@{ NSLocalizedDescriptionKey : NSLocalizedString(@"The page cannot be opened.", @"Error message when a page cannot be opened via Handoff, deep linking or a push notification") }];
            [Banner showError:error];
        }
        [UserConsentHelper waitCollectingConsentRelease];
    }] resume];
}

- (void)openSectionUid:(NSString *)sectionUid
{
    [UserConsentHelper waitCollectingConsentRetain];
    [[SRGDataProvider.currentDataProvider contentSectionForVendor:ApplicationConfiguration.sharedApplicationConfiguration.vendor uid:sectionUid published:YES withCompletionBlock:^(SRGContentSection * _Nullable contentSection, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
        if (contentSection) {
            // FIXME: is section always videoOrTV content type?
            SectionViewController *sectionViewController = [SectionViewController viewControllerForContentSection:contentSection contentType:ContentTypeVideoOrTV];
            [self.rootTabBarController pushViewController:sectionViewController animated:YES];
        }
        else {
            NSError *error = [NSError errorWithDomain:PlayErrorDomain
                                                 code:PlayErrorCodeNotFound
                                             userInfo:@{ NSLocalizedDescriptionKey : NSLocalizedString(@"The section cannot be opened.", @"Error message when a section cannot be opened via Handoff, deep linking or a push notification") }];
            [Banner showError:error];
        }
        [UserConsentHelper waitCollectingConsentRelease];
    }] resume];
}

#pragma mark KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (s_kvoContext == context) {
        if ([keyPath isEqualToString:PlaySRGSettingServiceEnvironment] || [keyPath isEqualToString:PlaySRGSettingUserLocation] || [keyPath isEqualToString:PlaySRGSettingProxyDetection] || [keyPath isEqualToString:PlaySRGSettingPosterImages] || [keyPath isEqualToString:PlaySRGSettingPodcastImages] ||  [keyPath isEqualToString:PlaySRGSettingAudioHomepageOption]) {
            // Entirely reload the view controller hierarchy to ensure all configuration changes are reflected in the
            // user interface. Scheduled for the next run loop to have the same code in the app delegate (updating the
            // data provider) executed first.
            dispatch_async(dispatch_get_main_queue(), ^{
                self.window.rootViewController = [[TabBarController alloc] init];
            });
        }
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

@end
