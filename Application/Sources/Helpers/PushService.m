//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "PushService.h"
#import "PushService+Private.h"

#import "ApplicationConfiguration.h"
#import "ApplicationSettings.h"
#import "Favorites.h"
#import "PlaySRG-Swift.h"
#import "UIView+PlaySRG.h"
#import "UserNotification.h"

@import UserNotifications;

NSString * const PushServiceDidReceiveNotification = @"PushServiceDidReceiveNotification";
NSString * const PushServiceBadgeDidChangeNotification = @"PushServiceBadgeDidChangeNotification";
NSString * const PushServiceStatusDidChangeNotification = @"PushServiceStatusDidChangeNotification";

NSString * const PushServiceEnabledKey = @"PushServiceEnabled";

@interface PushService ()

@property (nonatomic, readonly) NSString *appIdentifier;
@property (nonatomic, readonly) NSString *environmentIdentifier;

// Active push providers, ordered with the read source-of-truth first (Airship during the migration, the PushSDK once
// Airship is dropped). Writes fan out to all providers; reads come from the primary one (`firstObject`).
@property (nonatomic) NSArray<id<PushServiceProvider>> *providers;

@property (nonatomic, getter=isEnabled) BOOL enabled;

@end

@implementation PushService

#pragma mark Class methods

+ (PushService *)sharedService
{
    static dispatch_once_t s_onceToken;
    static PushService *s_pushService;
    dispatch_once(&s_onceToken, ^{
        s_pushService = [[PushService alloc] init];
    });
    return s_pushService;
}

#pragma mark Object lifecycle

- (instancetype)init
{
    if (self = [super init]) {
        static NSDictionary<NSNumber *, NSString *>  *s_appIdentifiers;
        static dispatch_once_t s_onceToken;
        dispatch_once(&s_onceToken, ^{
            s_appIdentifiers = @{ @(SRGVendorRSI) : @"playrsi",
                                  @(SRGVendorRTR) : @"playrtr",
                                  @(SRGVendorRTS) : @"playrts",
                                  @(SRGVendorSRF) : @"playsrf",
                                  @(SRGVendorSWI) : @"playswi" };
        });
        _appIdentifier = s_appIdentifiers[@(ApplicationConfiguration.sharedApplicationConfiguration.vendor)];
        if (! _appIdentifier) {
            return nil;
        }
        
        // Instantiate the available providers. Each one returns `nil` when it is not configured (no valid Airship
        // configuration / no push backend URL). If none is available, push notifications are not supported.
        NSMutableArray<id<PushServiceProvider>> *providers = [NSMutableArray array];
        AirshipPushServiceProvider *airshipProvider = [AirshipPushServiceProvider make];
        if (airshipProvider) {
            [providers addObject:airshipProvider];
        }
        PushSDKPushServiceProvider *pushSDKProvider = [PushSDKPushServiceProvider make];
        if (pushSDKProvider) {
            [providers addObject:pushSDKProvider];
        }
        if (providers.count == 0) {
            return nil;
        }
        _providers = providers.copy;
        
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(applicationDidBecomeActive:)
                                                   name:UIApplicationDidBecomeActiveNotification
                                                 object:nil];
    }
    return self;
}

#pragma mark Getters and setters

- (NSString *)environmentIdentifier
{
    NSString *environmentIdentifier = @"prod";
#if defined(DEBUG) || defined(NIGHTLY) || defined(BETA)
    NSArray<NSString *> *hostSubDomains = [ApplicationSettingServiceURL().host componentsSeparatedByString:@"."];
    if (hostSubDomains.count == 3) {
        if ([hostSubDomains.firstObject isEqualToString:@"il"]) {
            environmentIdentifier = @"prod";
        }
        else if ([hostSubDomains.firstObject isEqualToString:@"il-stage"]) {
            environmentIdentifier = @"stage";
        }
        else if ([hostSubDomains.firstObject isEqualToString:@"il-test"]) {
            environmentIdentifier = @"test";
        }
        else if ([hostSubDomains.firstObject isEqualToString:@"play-mmf"]) {
            environmentIdentifier = @"mmf";
        }
        else {
            environmentIdentifier = @"prod";
        }
    }
    if (hostSubDomains.count == 4
        && [hostSubDomains.firstObject isEqualToString:@"intlayer"]
        && [hostSubDomains[2] isEqualToString:@"srf"]
        && [hostSubDomains.lastObject isEqualToString:@"ch"]) {
        if ([hostSubDomains[1] isEqualToString:@"production"]) {
            environmentIdentifier = @"prod";
        }
        else if ([hostSubDomains[1] isEqualToString:@"stage"]) {
            environmentIdentifier = @"stage";
        }
        else if ([hostSubDomains[1] isEqualToString:@"test"]) {
            environmentIdentifier = @"test";
        }
        else {
            environmentIdentifier = @"prod";
        }
    }
#endif
    return environmentIdentifier;
}

- (NSSet<NSString *> *)subscribedShowURNs
{
    NSArray<NSString *> *tags = self.providers.firstObject.subscribedTags;
    if (tags.count == 0) {
        return [NSSet set];
    }
    
    NSMutableSet<NSString *> *URNs = [NSMutableSet set];
    for (NSString *tag in tags) {
        NSString *URN = [self showURNFromTag:tag];
        if (URN) {
            [URNs addObject:URN];
        }
    }
    
    return URNs.copy;
}

- (NSString *)deviceToken
{
    for (id<PushServiceProvider> provider in self.providers) {
        if (provider.deviceToken) {
            return provider.deviceToken;
        }
    }
    return nil;
}

- (NSString *)airshipIdentifier
{
    for (id<PushServiceProvider> provider in self.providers) {
        if (provider.identifier) {
            return provider.identifier;
        }
    }
    return nil;
}

#pragma mark Setup

- (void)setupWithLaunchingWithOptions:(NSDictionary<UIApplicationLaunchOptionsKey,id> *)launchOptions
{
    for (id<PushServiceProvider> provider in self.providers) {
        [provider setupWithLaunchOptions:launchOptions];
    }
    
    // The system authorization status is the single source of truth, independently of the active providers.
    [self updateEnabledStatus];
    
    // Seed every provider with the current subscription state stored in SRG User Data, keeping a freshly added provider
    // (e.g. the PushSDK during migration) in sync.
    [self synchronizeSubscriptions];
}

// Reflects the system push authorization status, regardless of the active providers.
- (void)updateEnabledStatus
{
    [[UNUserNotificationCenter currentNotificationCenter] getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings * _Nonnull settings) {
        dispatch_async(dispatch_get_main_queue(), ^{
            BOOL enabled = (settings.authorizationStatus == UNAuthorizationStatusAuthorized);
            if (enabled != self.enabled) {
                self.enabled = enabled;
                [NSNotificationCenter.defaultCenter postNotificationName:PushServiceStatusDidChangeNotification
                                                                  object:self
                                                                userInfo:@{ PushServiceEnabledKey : @(enabled) }];
            }
        });
    }];
}

#pragma mark Badge management

- (void)resetApplicationBadge
{
    [self.providers.firstObject resetBadge];
    [NSNotificationCenter.defaultCenter postNotificationName:PushServiceBadgeDidChangeNotification object:self];
}

- (void)updateApplicationBadge
{
    NSInteger unreadNotificationCount = UserNotification.unreadNotifications.count;
    
    if (UIApplication.sharedApplication.applicationIconBadgeNumber > unreadNotificationCount) {
        [self.providers.firstObject setBadgeNumber:unreadNotificationCount];
        [NSNotificationCenter.defaultCenter postNotificationName:PushServiceBadgeDidChangeNotification object:self];
    }
}

#pragma mark Subscription management

- (NSString *)tagForShowURN:(NSString *)URN
{
    return [NSString stringWithFormat:@"%@|%@|%@|%@", self.appIdentifier, UserNotificationTypeString(UserNotificationTypeNewOnDemandContentAvailable), self.environmentIdentifier, URN];
}

- (NSString *)showURNFromTag:(NSString *)tag
{
    NSArray<NSString *> *components = [tag componentsSeparatedByString:@"|"];
    if (components.count < 4) {
        return nil;
    }
    
    if (! [components[1] isEqualToString:UserNotificationTypeString(UserNotificationTypeNewOnDemandContentAvailable)]) {
        return nil;
    }
    
    if (! [components[2] isEqualToString:self.environmentIdentifier]) {
        return nil;
    }
    
    return components[3];
}

// Derive the desired tag set from SRG User Data (the source of truth) and reconcile every provider. Callers must ensure
// SRG User Data has already been updated before invoking any subscription change.
- (void)synchronizeSubscriptions
{
    NSMutableArray<NSString *> *tags = [NSMutableArray array];
    for (NSString *URN in FavoritesShowURNs()) {
        if (FavoritesIsSubscribedToShowURN(URN)) {
            [tags addObject:[self tagForShowURN:URN]];
        }
    }
    
    for (id<PushServiceProvider> provider in self.providers) {
        [provider setSubscribedTags:tags];
    }
}

#pragma mark Push registration

- (void)registerDeviceToken:(NSData *)deviceToken
{
    for (id<PushServiceProvider> provider in self.providers) {
        [provider registerDeviceToken:deviceToken];
    }
}

- (void)applicationDidFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
    for (id<PushServiceProvider> provider in self.providers) {
        [provider didFailToRegisterForRemoteNotificationsWithError:error];
    }
}

#pragma mark Consent

- (void)setAnalyticsConsentGranted:(BOOL)granted
{
    for (id<PushServiceProvider> provider in self.providers) {
        [provider setAnalyticsConsentGranted:granted];
    }
}

#pragma mark Actions

- (BOOL)presentSystemAlertForPushNotifications
{
    if (self.enabled) {
        return NO;
    }
    [[UNUserNotificationCenter currentNotificationCenter] requestAuthorizationWithOptions:(UNAuthorizationOptionAlert | UNAuthorizationOptionBadge | UNAuthorizationOptionSound)
                                                                        completionHandler:^(BOOL granted, NSError *error) {
        if (granted) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [UIApplication.sharedApplication registerForRemoteNotifications];
            });
        }
    }];
    return YES;
}

#pragma mark Notification handling

- (void)didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    [NSNotificationCenter.defaultCenter postNotificationName:PushServiceDidReceiveNotification object:self];
    
    for (id<PushServiceProvider> provider in self.providers) {
        if ([provider handleRemoteNotification:userInfo fetchCompletionHandler:completionHandler]) {
            return;
        }
    }
    completionHandler(UIBackgroundFetchResultNewData);
}

- (void)handleNotificationResponse:(UNNotificationResponse *)notificationResponse withCompletionHandler:(void (^)(void))completionHandler
{
    [self processNotificationResponse:notificationResponse];
    
    for (id<PushServiceProvider> provider in self.providers) {
        if ([provider handleNotificationResponse:notificationResponse completionHandler:completionHandler]) {
            return;
        }
    }
    completionHandler();
}

- (void)willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions))completionHandler
{
    [NSNotificationCenter.defaultCenter postNotificationName:PushServiceDidReceiveNotification object:self];
    
    for (id<PushServiceProvider> provider in self.providers) {
        if ([provider willPresentNotification:notification completionHandler:completionHandler]) {
            return;
        }
    }
    completionHandler(UNNotificationPresentationOptionList | UNNotificationPresentationOptionBanner | UNNotificationPresentationOptionBadge | UNNotificationPresentationOptionSound);
}

// Application-level handling of a notification response (history, deep linking, analytics), shared by all providers.
- (void)processNotificationResponse:(UNNotificationResponse *)notificationResponse
{
    UNNotification *notification = notificationResponse.notification;
    if (notification) {
        UserNotification *savedNotification = [[UserNotification alloc] initWithNotification:notification];
        [UserNotification saveNotification:savedNotification read:YES];
    }
    
    UNNotificationContent *notificationContent = notification.request.content;
    NSDictionary *userInfo = notificationContent.userInfo;
    NSString *channelUid = userInfo[@"channelId"];
    
    if (userInfo[@"media"]) {
        NSString *mediaURN = userInfo[@"media"];
        NSInteger startTime = [userInfo[@"startTime"] integerValue];
        SceneDelegate *sceneDelegate = UIApplication.sharedApplication.mainSceneDelegate;
        [sceneDelegate openMediaWithURN:mediaURN startTime:startTime channelUid:channelUid fromPushNotification:YES completionBlock:^{
            [[AnalyticsEventObjC notificationWithAction:AnalyticsNotificationActionPlayMedia
                                                   from:AnalyticsNotificationFromOperatingSystem
                                                    uid:mediaURN
                                         overrideSource:userInfo[@"show"]
                                           overrideType:userInfo[@"type"]]
             send];
        }];
    }
    else if (userInfo[@"show"]) {
        NSString *showURN = userInfo[@"show"];
        SceneDelegate *sceneDelegate = UIApplication.sharedApplication.mainSceneDelegate;
        [sceneDelegate openShowWithURN:showURN channelUid:channelUid fromPushNotification:YES completionBlock:^{
            [[AnalyticsEventObjC notificationWithAction:AnalyticsNotificationActionDisplayShow
                                                   from:AnalyticsNotificationFromOperatingSystem
                                                    uid:showURN
                                         overrideSource:nil
                                           overrideType:userInfo[@"type"]]
             send];
        }];
    }
    else {
        [[AnalyticsEventObjC notificationWithAction:AnalyticsNotificationActionAlert
                                               from:AnalyticsNotificationFromOperatingSystem
                                                uid:notificationContent.body
                                     overrideSource:nil
                                       overrideType:userInfo[@"type"]]
         send];
    }
}

#pragma mark Notifications

- (void)applicationDidBecomeActive:(NSNotification *)notification
{
    // Ensures the state is updated after if the user returns to the app (push notification settings might have been
    // changed)
    [self updateEnabledStatus];
}

@end

@implementation PushService (Helpers)

- (BOOL)requestSubscriptionAuthorization
{
    if (self.enabled) {
        return YES;
    }
    
    if (! [self presentSystemAlertForPushNotifications]) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Enable notifications?", @"Question displayed at the top of an alert asking the user to enable notifications")
                                                                                 message:NSLocalizedString(@"For the application to inform you when a new episode is available, notifications must be enabled.", @"Explanation displayed in the alert asking the user to enable notifications")
                                                                          preferredStyle:UIAlertControllerStyleAlert];
        [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Enable in system settings", @"Title of a button to propose the user to enable notifications in the system settings") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            NSURL *URL = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
            [UIApplication.sharedApplication openURL:URL options:@{} completionHandler:nil];
        }]];
        [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"Title of a cancel button") style:UIAlertActionStyleDefault handler:nil]];
        
        UIViewController *topViewController = UIApplication.sharedApplication.mainTopViewController;
        [topViewController presentViewController:alertController animated:YES completion:nil];
    }
    return NO;
}

@end
