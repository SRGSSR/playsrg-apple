//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "PlayAppDelegate.h"

#import "ApplicationConfiguration.h"
#import "ApplicationSettings.h"
#import "ApplicationSettingsConstants.h"
#import "Banner.h"
#import "CalendarViewController.h"
#import "DeepLinkService.h"
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
#import "ShowsViewController.h"
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
@import Fingertips;
#endif

static void *s_kvoContext = &s_kvoContext;

@interface PlayAppDelegate ()

@property (nonatomic) DeepLinkService *deepLinkService;

@end

@implementation PlayAppDelegate

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

#pragma mark Application lifecycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    NSAssert(NSClassFromString(@"ASIdentifierManager") == Nil, @"No implicit AdSupport.framework dependency must be found");
    
    [AVAudioSession.sharedInstance setCategory:AVAudioSessionCategoryPlayback error:NULL];
    
    // Processes run once in the lifetime of the application
    PlayApplicationRunOnce(^(void (^completionHandler)(BOOL success)) {
        [PlayFirebaseConfiguration clearFirebaseConfigurationCache];
        completionHandler(YES);
    }, @"FirebaseConfigurationReset", nil);
    
    // The configuration file, copied at build time in the main product bundle, has the standard Firebase
    // configuration filename
    if ([NSBundle.mainBundle pathForResource:@"GoogleService-Info" ofType:@"plist"]) {
        [FIRApp configure];
    }
    
    ApplicationConfiguration *applicationConfiguration = ApplicationConfiguration.sharedApplicationConfiguration;
    self.deepLinkService = [[DeepLinkService alloc] initWithServiceURL:applicationConfiguration.middlewareURL];
    
    NSURL *identityWebserviceURL = applicationConfiguration.identityWebserviceURL;
    NSURL *identityWebsiteURL = applicationConfiguration.identityWebsiteURL;
    if (identityWebserviceURL && identityWebsiteURL) {
        SRGIdentityService.currentIdentityService = [[SRGIdentityService alloc] initWithWebserviceURL:identityWebserviceURL websiteURL:identityWebsiteURL];
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(userDidCancelLogin:)
                                                   name:SRGIdentityServiceUserDidCancelLoginNotification
                                                 object:SRGIdentityService.currentIdentityService];
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(userDidLogin:)
                                                   name:SRGIdentityServiceUserDidLoginNotification
                                                 object:SRGIdentityService.currentIdentityService];
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(didUpdateAccount:)
                                                   name:SRGIdentityServiceDidUpdateAccountNotification
                                                 object:SRGIdentityService.currentIdentityService];
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(userDidLogout:)
                                                   name:SRGIdentityServiceUserDidLogoutNotification
                                                 object:SRGIdentityService.currentIdentityService];
    }
    
    NSURL *libraryDirectoryURL = [NSURL fileURLWithPath:NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES).firstObject];
    NSURL *storeFileURL = [libraryDirectoryURL URLByAppendingPathComponent:@"PlayData.sqlite"];
    SRGUserData.currentUserData = [[SRGUserData alloc] initWithStoreFileURL:storeFileURL
                                                                 serviceURL:applicationConfiguration.userDataServiceURL
                                                            identityService:SRGIdentityService.currentIdentityService];
    
    GoogleCastSetup();
    
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(playbackDidContinueAutomatically:)
                                               name:SRGLetterboxPlaybackDidContinueAutomaticallyNotification
                                             object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(settingDidChange:)
                                               name:kIASKAppSettingChanged
                                             object:nil];
    
#if defined(DEBUG) || defined(NIGHTLY) || defined(BETA)
    self.window = [[MBFingerTipWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
#else
    self.window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
#endif
    
    [self setPresenterModeEnabled:ApplicationSettingPresenterModeEnabled()];
    
    self.window.backgroundColor = UIColor.blackColor;
    self.window.accessibilityIgnoresInvertColors = YES;
    
    [self setupAnalytics];
    [self setupDataProvider];
    
    // Use appropriate voice over language for the whole application
    application.accessibilityLanguage = applicationConfiguration.voiceOverLanguageCode;
#if defined(DEBUG) || defined(NIGHTLY) || defined(BETA)
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    [defaults addObserver:self forKeyPath:PlaySRGSettingServiceURL options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld  context:s_kvoContext];
    [defaults addObserver:self forKeyPath:PlaySRGSettingUserLocation options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:s_kvoContext];
#endif
    
    // Various setups
#ifndef DEBUG
    [self setupAppCenter];
#endif
    
    // Clean downloaded folder
    [Download removeUnusedDownloadedFiles];
    
    // Setup view controller hierarchy
    [self.window makeKeyAndVisible];
    self.window.rootViewController = [[TabBarController alloc] init];
    
    [self checkForForcedUpdates];
    
    // Processes run once in the lifetime of the application
    __block BOOL firstLaunchDone = YES;
    PlayApplicationRunOnce(^(void (^completionHandler)(BOOL success)) {
        firstLaunchDone = NO;
        completionHandler(YES);
    }, @"FirstLaunchDone", nil);
    
    [PushService.sharedService setup];
    [PushService.sharedService updateApplicationBadge];
    
    FavoritesSetup();
    
    // Local objects migration
    WatchLaterMigrate();
    FavoritesMigrate();
    
    // Processes run once in the lifetime of the application
    PlayApplicationRunOnce(^(void (^completionHandler)(BOOL success)) {
        [UIImage srg_clearVectorImageCache];
        completionHandler(YES);
    }, @"ClearVectorImageCache2", nil);
    
    // Open the application via 3D touch shortcut if needed
    BOOL shouldNotPerformAdditionalDelegateHandling = YES;
    UIApplicationShortcutItem *launchedShortcutItem = launchOptions[UIApplicationLaunchOptionsShortcutItemKey];
    if (launchedShortcutItem) {
        shouldNotPerformAdditionalDelegateHandling = NO;
        [self handleShortcutItem:launchedShortcutItem];
    }
    
    return shouldNotPerformAdditionalDelegateHandling;
}

// Quick Actions with 3D Touch
- (void)application:(UIApplication *)application performActionForShortcutItem:(UIApplicationShortcutItem *)shortcutItem completionHandler:(void (^ _Nonnull)(BOOL succeeded))completionHandler
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
- (BOOL)application:(UIApplication *)application openURL:(NSURL *)URL options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options
{
    AnalyticsSource analyticsSource = ([URL.scheme isEqualToString:@"http"] || [URL.scheme isEqualToString:@"https"]) ? AnalyticsSourceDeepLink : AnalyticsSourceSchemeURL;
    
    NSArray<DeeplinkAction> *supportedActions = @[ DeeplinkActionMedia, DeeplinkActionShow, DeeplinkActionTopic, DeeplinkActionHome,
                                                   DeeplinkActionAZ, DeeplinkActionByDate, DeeplinkActionSection, DeeplinkActionSearch, DeeplinkActionLink ];
    
    NSURLComponents *URLComponents = [NSURLComponents componentsWithURL:URL resolvingAgainstBaseURL:YES];
    if (! [supportedActions containsObject:URLComponents.host.lowercaseString]) {
        NSURL *deepLinkURL = [self.deepLinkService schemeURLFromWebURL:URL];
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
                labels.extraValue1 = options[UIApplicationOpenURLOptionsSourceApplicationKey];
                [SRGAnalyticsTracker.sharedTracker trackHiddenEventWithName:AnalyticsTitleOpenURL labels:labels];
            }];
            return YES;
        }
        
        NSString *showURN = URLComponents.path.lastPathComponent;
        if ([action isEqualToString:DeeplinkActionShow] && showURN) {
            NSString *channelUid = [self valueFromURLComponents:URLComponents withParameterName:@"channel_id"];
            [self openShowWithURN:showURN channelUid:channelUid fromPushNotification:NO completionBlock:^{
                SRGAnalyticsHiddenEventLabels *labels = [[SRGAnalyticsHiddenEventLabels alloc] init];
                labels.source = analyticsSource;
                labels.type = AnalyticsTypeActionDisplayShow;
                labels.value = showURN;
                labels.extraValue1 = options[UIApplicationOpenURLOptionsSourceApplicationKey];
                [SRGAnalyticsTracker.sharedTracker trackHiddenEventWithName:AnalyticsTitleOpenURL labels:labels];
            }];
            return YES;
        }
        
        NSString *topicURN = URLComponents.path.lastPathComponent;
        if ([action isEqualToString:DeeplinkActionTopic] && topicURN) {
            [self openTopicWithURN:topicURN completionBlock:^{
                SRGAnalyticsHiddenEventLabels *labels = [[SRGAnalyticsHiddenEventLabels alloc] init];
                labels.source = analyticsSource;
                labels.type = AnalyticsTypeActionDisplayPage;
                labels.value = topicURN;
                labels.extraValue1 = options[UIApplicationOpenURLOptionsSourceApplicationKey];
                [SRGAnalyticsTracker.sharedTracker trackHiddenEventWithName:AnalyticsTitleOpenURL labels:labels];
            }];
            return YES;
        }
        
        NSArray<DeeplinkAction> *pageActions = @[ DeeplinkActionHome, DeeplinkActionAZ, DeeplinkActionByDate, DeeplinkActionSearch ];
        if ([pageActions containsObject:action]) {
            NSString *channelUid = [self valueFromURLComponents:URLComponents withParameterName:@"channel_id"];
            [self openPageWithAction:action channelUid:channelUid URLComponents:URLComponents completionBlock:^{
                SRGAnalyticsHiddenEventLabels *labels = [[SRGAnalyticsHiddenEventLabels alloc] init];
                labels.source = analyticsSource;
                labels.type = AnalyticsTypeActionDisplayPage;
                labels.value = action;
                labels.extraValue1 = options[UIApplicationOpenURLOptionsSourceApplicationKey];
                [SRGAnalyticsTracker.sharedTracker trackHiddenEventWithName:AnalyticsTitleOpenURL labels:labels];
            }];
            return YES;
        }
        
        NSString *sectionUid = URLComponents.path.lastPathComponent;
        if ([action isEqualToString:DeeplinkActionSection] && sectionUid) {
            [self openSectionWithUid:sectionUid completionBlock:^{
                SRGAnalyticsHiddenEventLabels *labels = [[SRGAnalyticsHiddenEventLabels alloc] init];
                labels.source = analyticsSource;
                labels.type = AnalyticsTypeActionDisplayPage;
                labels.value = sectionUid;
                labels.extraValue1 = options[UIApplicationOpenURLOptionsSourceApplicationKey];
                [SRGAnalyticsTracker.sharedTracker trackHiddenEventWithName:AnalyticsTitleOpenURL labels:labels];
            }];
        }
        
        NSString *URLString = [self valueFromURLComponents:URLComponents withParameterName:@"url"];
        NSURL *URL = URLString ? [NSURL URLWithString:URLString] : nil;
        if ([action isEqualToString:DeeplinkActionLink] && URL) {
            [UIApplication.sharedApplication play_openURL:URL withCompletionHandler:^(BOOL success) {
                SRGAnalyticsHiddenEventLabels *labels = [[SRGAnalyticsHiddenEventLabels alloc] init];
                labels.source = analyticsSource;
                labels.type = AnalyticsTypeActionDisplayURL;
                labels.value = URLString;
                labels.extraValue1 = options[UIApplicationOpenURLOptionsSourceApplicationKey];
                [SRGAnalyticsTracker.sharedTracker trackHiddenEventWithName:AnalyticsTitleOpenURL labels:labels];
            }];
            return YES;
        }
        
        SRGAnalyticsHiddenEventLabels *labels = [[SRGAnalyticsHiddenEventLabels alloc] init];
        labels.source = analyticsSource;
        labels.type = AnalyticsTypeActionOpenPlayApp;
        labels.extraValue1 = options[UIApplicationOpenURLOptionsSourceApplicationKey];
        [SRGAnalyticsTracker.sharedTracker trackHiddenEventWithName:AnalyticsTitleOpenURL labels:labels];
        
        return YES;
    }
    
    return NO;
}

// https://support.urbanairship.com/hc/en-us/articles/213492483-iOS-Badging-and-Auto-Badging
- (void)applicationDidBecomeActive:(UIApplication *)application
{
    [PushService.sharedService updateApplicationBadge];
}

// https://support.urbanairship.com/hc/en-us/articles/213492483-iOS-Badging-and-Auto-Badging
- (void)application:(UIApplication *)application didReceiveRemoteNotification:(nonnull NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    [PushService.sharedService updateApplicationBadge];
    completionHandler(UIBackgroundFetchResultNoData);
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

- (BOOL)application:(UIApplication *)application willContinueUserActivityWithType:(NSString *)userActivityType
{
    return [userActivityType isEqualToString:[NSBundle.mainBundle.bundleIdentifier stringByAppendingString:@".playing"]]
        || [userActivityType isEqualToString:[NSBundle.mainBundle.bundleIdentifier stringByAppendingString:@".displaying"]]
        || [userActivityType isEqualToString:NSUserActivityTypeBrowsingWeb];
}

- (BOOL)application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void (^)(NSArray<id<UIUserActivityRestoring>> *))restorationHandler
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
        
        return (mediaURN != nil);
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
        
        return (showURN != nil);
    }
    else if ([userActivity.activityType isEqualToString:NSUserActivityTypeBrowsingWeb]) {
        return [self application:UIApplication.sharedApplication openURL:userActivity.webpageURL options:@{}];
    }
    else {
        return NO;
    }
}

- (void)application:(UIApplication *)application didFailToContinueUserActivityWithType:(NSString *)userActivityType error:(NSError *)error
{
    PlayLogWarning(@"application", @"Could not retrieve user activity for %@. Reason: %@", userActivityType, error);
    [Banner showError:error inViewController:nil];
}

#pragma mark Helpers

- (void)setupAppCenter
{
    NSString *appCenterSecret = [NSBundle.mainBundle objectForInfoDictionaryKey:@"AppCenterSecret"];
    if (appCenterSecret.length == 0) {
        return;
    }
    
    MSACDistribute.updateTrack = MSACUpdateTrackPrivate;
    [MSACAppCenter start:appCenterSecret withServices:@[ MSACCrashes.class, MSACDistribute.class ]];
}

- (void)setupDataProvider
{
    [SRGNetworkActivityManagement enable];
    
    NSURL *serviceURL = ApplicationSettingServiceURL();
    SRGDataProvider *dataProvider = [[SRGDataProvider alloc] initWithServiceURL:serviceURL];
#if defined(DEBUG) || defined(NIGHTLY) || defined(BETA)
    dataProvider.globalParameters = ApplicationSettingGlobalParameters();
    
    NSString *environment = nil;
    
    NSString *host = serviceURL.host;
    if ([host containsString:@"test"]) {
        environment = @"test";
    }
    else if ([host containsString:@"stage"]) {
        environment = @"stage";
    }
    
    if (environment) {
        static dispatch_once_t s_onceToken2;
        static NSDictionary<NSNumber *, NSString *> *s_suffixes;
        dispatch_once(&s_onceToken2, ^{
            s_suffixes = @{ @(SRGVendorRSI) : @"rsi",
                            @(SRGVendorRTR) : @"rtr",
                            @(SRGVendorRTS) : @"rts",
                            @(SRGVendorSRF) : @"srf",
                            @(SRGVendorSWI) : @"swi" };
        });
        SRGVendor vendor = ApplicationConfiguration.sharedApplicationConfiguration.vendor;
        NSString *suffix = s_suffixes[@(vendor)];
        if (suffix) {
            NSString *URLString = [NSString stringWithFormat:@"https://srgplayer-%@.%@.srf.ch/play/", suffix, environment];
            [ApplicationConfiguration.sharedApplicationConfiguration setOverridePlayURL:[NSURL URLWithString:URLString]];
        }
    }
    else {
        [ApplicationConfiguration.sharedApplicationConfiguration setOverridePlayURL:nil];
    }
#endif
    SRGDataProvider.currentDataProvider = dataProvider;
}

- (void)setupAnalytics
{
    ApplicationConfiguration *applicationConfiguration = ApplicationConfiguration.sharedApplicationConfiguration;
    
    SRGAnalyticsConfiguration *configuration = [[SRGAnalyticsConfiguration alloc] initWithBusinessUnitIdentifier:applicationConfiguration.analyticsBusinessUnitIdentifier
                                                                                                       container:applicationConfiguration.analyticsContainer
                                                                                                        siteName:applicationConfiguration.siteName];
    [SRGAnalyticsTracker.sharedTracker startWithConfiguration:configuration
                                              identityService:SRGIdentityService.currentIdentityService];
}

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

- (void)openShowListWithRadioChannel:(RadioChannel *)radioChannel atIndex:(NSString *)index
{
    ShowsViewController *showsViewController = [[ShowsViewController alloc] initWithRadioChannel:radioChannel alphabeticalIndex:index];
    [self.rootTabBarController pushViewController:showsViewController animated:YES];
}

- (void)openCalendarAtDate:(NSDate *)date withRadioChannel:(RadioChannel *)radioChannel
{
    CalendarViewController *calendarViewController = [[CalendarViewController alloc] initWithRadioChannel:radioChannel date:date];
    [self.rootTabBarController pushViewController:calendarViewController animated:YES];
}

#pragma mark Forced updates

- (void)checkForForcedUpdates
{
    NSURL *URL = [NSURL URLWithString:@"api/v1/update/check" relativeToURL:ApplicationConfiguration.sharedApplicationConfiguration.middlewareURL];
    NSURLComponents *URLComponents = [NSURLComponents componentsWithString:URL.absoluteString];
    
    NSString *bundleIdentifier = [NSBundle.mainBundle objectForInfoDictionaryKey:@"CFBundleIdentifier"];
    NSString *version = [NSBundle.mainBundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
#if defined(DEBUG) || defined(NIGHTLY) || defined(BETA)
    version = [version componentsSeparatedByString:@"-"].firstObject;
#endif
    URLComponents.queryItems = @[ [NSURLQueryItem queryItemWithName:@"package" value:bundleIdentifier],
                                  [NSURLQueryItem queryItemWithName:@"version" value:version],
                                  [NSURLQueryItem queryItemWithName:@"platform" value:UIDevice.currentDevice.systemName],
                                  [NSURLQueryItem queryItemWithName:@"platform_version" value:UIDevice.currentDevice.systemVersion] ];
    
    [[SRGRequest objectRequestWithURLRequest:[NSURLRequest requestWithURL:URLComponents.URL] session:NSURLSession.sharedSession parser:^id _Nullable(NSData * _Nonnull data, NSError * _Nullable __autoreleasing * _Nullable pError) {
        NSDictionary *JSONDictionary = SRGNetworkJSONDictionaryParser(data, pError);
        if (! JSONDictionary) {
            return nil;
        }
        
        return [MTLJSONAdapter modelOfClass:UpdateInfo.class fromJSONDictionary:JSONDictionary error:pError];
    } completionBlock:^(UpdateInfo * _Nullable updateInfo, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            PlayLogWarning(@"application", @"Could not retrieve update information. Reason: %@", error);
            return;
        }
        
        switch (updateInfo.type) {
            case UpdateTypeMandatory: {
                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Mandatory update", @"Message title displayed when the user is forced to update the application.")
                                                                                         message:updateInfo.reason
                                                                                  preferredStyle:UIAlertControllerStyleAlert];
                [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Update", @"Title of the button to update the application") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                    [self showStorePage];
                }]];
                [self.window.play_topViewController presentViewController:alertController animated:YES completion:nil];
                break;
            }
                
            case UpdateTypeOptional: {
                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Recommended update", @"Message title displayed when the user is recommended to update the application.")
                                                                                         message:updateInfo.reason
                                                                                  preferredStyle:UIAlertControllerStyleAlert];
                [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Skip", @"Title of the button to skip updating the application") style:UIAlertActionStyleDefault handler:nil]];
                [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Update", @"Title of the button to update the application") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                    [self showStorePage];
                }]];
                [self.window.play_topViewController presentViewController:alertController animated:YES completion:nil];
                break;
            }
                
            default: {
                break;
            }
        }
    }] resume];
}

- (void)showStorePage
{
    SKStoreProductViewController *productViewController = [[SKStoreProductViewController  alloc] init];
    productViewController.modalPresentationStyle = UIModalPresentationFullScreen;
    productViewController.delegate = self;
    
    ApplicationConfiguration *applicationConfiguration = ApplicationConfiguration.sharedApplicationConfiguration;
    [productViewController loadProductWithParameters:@{ SKStoreProductParameterITunesItemIdentifier : applicationConfiguration.appStoreProductIdentifier } completionBlock:^(BOOL result, NSError * _Nullable error) {
        if (error) {
            [self checkForForcedUpdates];
        }
    }];
    [self.window.play_topViewController presentViewController:productViewController animated:YES completion:nil];
}

#pragma mark SKStoreProductViewControllerDelegate protocol

- (void)productViewControllerDidFinish:(SKStoreProductViewController *)viewController
{
    [self.window.play_topViewController dismissViewControllerAnimated:YES completion:^{
        [self checkForForcedUpdates];
    }];
}

#pragma mark Actions

- (void)closeWhatsNew:(id)sender
{
    [self.window.play_topViewController dismissViewControllerAnimated:YES completion:^{
        [self checkForForcedUpdates];
    }];
}

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

#pragma mark Notifications

- (void)playbackDidContinueAutomatically:(NSNotification *)notification
{
    SRGMedia *media = notification.userInfo[SRGLetterboxMediaKey];
    if (media) {
        SRGAnalyticsHiddenEventLabels *labels = [[SRGAnalyticsHiddenEventLabels alloc] init];
        labels.source = AnalyticsSourceAutomatic;
        labels.type = AnalyticsTypeActionPlayMedia;
        labels.value = media.URN;
        
        SRGLetterboxController *letterboxController = notification.object;
        Playlist *playlist = [letterboxController.playlistDataSource isKindOfClass:Playlist.class] ? (Playlist *)letterboxController.playlistDataSource : nil;
        labels.extraValue1 = playlist.recommendationUid;
        [SRGAnalyticsTracker.sharedTracker trackHiddenEventWithName:AnalyticsTitleContinuousPlayback labels:labels];
    }
}

- (void)userDidCancelLogin:(NSNotification *)notification
{
    SRGAnalyticsHiddenEventLabels *labels = [[SRGAnalyticsHiddenEventLabels alloc] init];
    labels.source = AnalyticsSourceButton;
    labels.type = AnalyticsTypeActionCancelLogin;
    [SRGAnalyticsTracker.sharedTracker trackHiddenEventWithName:AnalyticsTitleIdentity labels:labels];
}

- (void)userDidLogin:(NSNotification *)notification
{
    SRGAnalyticsHiddenEventLabels *labels = [[SRGAnalyticsHiddenEventLabels alloc] init];
    labels.source = AnalyticsSourceButton;
    labels.type = AnalyticsTypeActionLogin;
    [SRGAnalyticsTracker.sharedTracker trackHiddenEventWithName:AnalyticsTitleIdentity labels:labels];
}

- (void)didUpdateAccount:(NSNotification *)notification
{
    SRGAccount *account = notification.userInfo[SRGIdentityServiceAccountKey];
    if (account) {
        [NSUserDefaults.standardUserDefaults setObject:account.emailAddress forKey:PlaySRGSettingLastLoggedInEmailAddress];
        [NSUserDefaults.standardUserDefaults synchronize];
    }
}

- (void)userDidLogout:(NSNotification *)notification
{
    BOOL unexpectedLogout = [notification.userInfo[SRGIdentityServiceUnauthorizedKey] boolValue];
    if (unexpectedLogout) {
        // Display the warning banner after a while. Account view controller may take time to disappear, due to the animation.
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [Banner showWithStyle:BannerStyleWarning
                          message:NSLocalizedString(@"You have been automatically logged out. Login again to keep your data synchronized across devices.", @"Notification displayed when the user has been logged out unexpectedly.")
                            image:[UIImage imageNamed:@"account"]
                           sticky:YES
                 inViewController:nil];
        });
    }
    
    SRGAnalyticsHiddenEventLabels *labels = [[SRGAnalyticsHiddenEventLabels alloc] init];
    labels.source = unexpectedLogout ? AnalyticsSourceAutomatic : AnalyticsSourceButton;
    labels.type = AnalyticsTypeActionLogout;
    [SRGAnalyticsTracker.sharedTracker trackHiddenEventWithName:AnalyticsTitleIdentity labels:labels];
}

- (void)settingDidChange:(NSNotification *)notification
{
    NSNumber *presenterModeEnabled = notification.userInfo[PlaySRGSettingPresenterModeEnabled];
    if (presenterModeEnabled) {
        [self setPresenterModeEnabled:presenterModeEnabled.boolValue];
    }
}

#pragma mark KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (s_kvoContext == context) {
        if ([keyPath isEqualToString:PlaySRGSettingServiceURL] || [keyPath isEqualToString:PlaySRGSettingUserLocation]) {
            id oldValue = change[NSKeyValueChangeOldKey];
            id newValue = change[NSKeyValueChangeNewKey];
            
            if (! [newValue isEqual:oldValue]) {
                [[NSURLCache sharedURLCache] removeAllCachedResponses];
                
                [self setupDataProvider];
                
                // Stop the current player
                // TODO: For perfectly safe behavior when the service URL is changed, we should have all Letterbox
                //       controllers observe URL settings change and do the following in such cases. This is probably
                //       overkill for the time being.
                
                SRGLetterboxController *serviceController = SRGLetterboxService.sharedService.controller;
                [serviceController reset];
                ApplicationConfigurationApplyControllerSettings(serviceController);
                
                // Entirely reload the view controller hierarchy to reflect the changes
                self.window.rootViewController = [[TabBarController alloc] init];
            }
        }
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

@end
