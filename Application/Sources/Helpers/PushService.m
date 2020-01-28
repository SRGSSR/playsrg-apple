//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "PushService.h"
#import "PushService+Private.h"

#import "ApplicationConfiguration.h"
#import "ApplicationSettings.h"
#import "PlayAppDelegate.h"
#import "Notification.h"

#import <CoconutKit/CoconutKit.h>
#import <libextobjc/libextobjc.h>
#import <UrbanAirship-iOS-SDK/AirshipKit.h>
#import <UserNotifications/UserNotifications.h>

NSString * const PushServiceDidReceiveNotification = @"PushServiceDidReceiveNotification";

@interface PushService () <UAPushNotificationDelegate>

@property (nonatomic, readonly) NSString *appIdentifier;
@property (nonatomic, readonly) NSString *environmentIdentifier;

@property (nonatomic) UAConfig *configuration;

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
        
        NSString *configurationFilePath = [NSBundle.mainBundle pathForResource:@"AirshipConfig" ofType:@"plist"];
        if (! configurationFilePath) {
            return nil;
        }
        
        UAConfig *configuration = [UAConfig configWithContentsOfFile:configurationFilePath];
        if (! [configuration validate]) {
            return nil;
        }
        
        self.configuration = configuration;
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
    NSArray<NSString *> *tags = [UAirship push].tags;
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

- (BOOL)isEnabled
{
    // iOS 10 and above: Even if alerts have been disabled by the user, `UIApplication.registeredForRemoteNotifications`
    // will still return `YES` if the target supports silent notifications (introduced with iOS 10 rich notifications).
    // We nust retrieve the proper authorization status from iOS 10 `UNUserNotificationCenter`, providing finer-grained
    // information covering these new use cases.
    if (@available(iOS 10, *)) {
        // Make asynchronous call synchronous
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        
        __block UNNotificationSettings *notificationSettings = nil;
        [[UNUserNotificationCenter currentNotificationCenter] getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings * _Nonnull settings) {
            notificationSettings = settings;
            dispatch_semaphore_signal(semaphore);
        }];
        
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        return notificationSettings.authorizationStatus == UNAuthorizationStatusAuthorized;
    }
    // Before iOS 10: `UIApplication.registeredForRemoteNotifications` accurately reflects whether the user has authorized
    // notificartions or not.
    else {
        return UIApplication.sharedApplication.currentUserNotificationSettings.types != UIUserNotificationTypeNone;
    }
}

#pragma mark Setup

- (void)setup
{
    [UAirship takeOff:self.configuration];
    if (@available(iOS 10, *)) {
        [UAirship push].defaultPresentationOptions = (UNNotificationPresentationOptionAlert | UNNotificationPresentationOptionBadge | UNNotificationPresentationOptionSound);
    }
    [UAirship push].pushNotificationDelegate = self;
    [UAirship push].autobadgeEnabled = YES;
    
    [[UAirship inAppMessageManager] setEnabled:NO];
}

#pragma mark Badge management

- (void)resetApplicationBadge
{
    [[UAirship push] resetBadge];
}

- (void)updateApplicationBadge
{
    NSInteger unreadNotificationCount = Notification.unreadNotifications.count;
    
    if (UIApplication.sharedApplication.applicationIconBadgeNumber > unreadNotificationCount) {
        [[UAirship push] setBadgeNumber:unreadNotificationCount];
    }
}

#pragma mrk Subscription management

- (NSString *)tagForShowURN:(NSString *)URN
{
    return [NSString stringWithFormat:@"%@|%@|%@|%@", self.appIdentifier, NotificationTypeString(NotificationTypeNewOnDemandContentAvailable), self.environmentIdentifier, URN];
}

- (NSString *)tagForShow:(SRGShow *)show
{
    return [self tagForShowURN:show.URN];
}

- (NSString *)showURNFromTag:(NSString *)tag
{
    NSArray<NSString *> *components = [tag componentsSeparatedByString:@"|"];
    if (components.count < 4) {
        return nil;
    }
    
    if (! [components[1] isEqualToString:NotificationTypeString(NotificationTypeNewOnDemandContentAvailable)]) {
        return nil;
    }
    
    if (! [components[2] isEqualToString:self.environmentIdentifier]) {
        return nil;
    }
    
    return components[3];
}

- (void)subscribeToShowURNs:(NSSet<NSString *> *)URNs
{
    if (URNs.count == 0) {
        return;
    }
    
    for (NSString *URN in URNs) {
        [[UAirship push] addTag:[self tagForShowURN:URN]];
    }
    [[UAirship push] updateRegistration];
}

- (void)unsubscribeFromShowURNs:(NSSet<NSString *> *)URNs
{
    if (URNs.count == 0) {
        return;
    }
    
    for (NSString *URN in URNs) {
        [[UAirship push] removeTag:[self tagForShowURN:URN]];
    }
    [[UAirship push] updateRegistration];
}

- (BOOL)isSubscribedToShowURN:(NSString *)URN
{
    return [[UAirship push].tags containsObject:[self tagForShowURN:URN]];
}

#pragma mark Actions

- (BOOL)presentSystemAlertForPushNotifications
{
    // Lazily enable push notifications at the Urban Airship level, so that the user is asked the first time she
    // attempts to use the functionality.
    if (! [UAirship push].userPushNotificationsEnabled) {
        [UAirship push].userPushNotificationsEnabled = YES;
        return YES;
    }
    else {
        return NO;
    }
}

#pragma mark UAPushNotificationDelegate protocol

- (void)receivedNotificationResponse:(UANotificationResponse *)notificationResponse completionHandler:(void (^)(void))completionHandler
{
    if (@available(iOS 10, *)) {
        if (notificationResponse.notificationContent.notification) {
            Notification *notification = [[Notification alloc] initWithNotification:notificationResponse.notificationContent.notification];
            [Notification saveNotification:notification read:YES];
        }
    }
    
    UANotificationContent *notificationContent = notificationResponse.notificationContent;
    
    NSString *channelUid = notificationContent.notificationInfo[@"channelId"];
    
    if (notificationContent.notificationInfo[@"media"]) {
        NSString *mediaURN = notificationContent.notificationInfo[@"media"];
        NSInteger startTime = [notificationContent.notificationInfo[@"startTime"] integerValue];
        UIApplication *application = UIApplication.sharedApplication;
        PlayAppDelegate *appDelegate = (PlayAppDelegate *)application.delegate;
        [appDelegate openMediaWithURN:mediaURN startTime:startTime channelUid:channelUid fromPushNotification:YES completionBlock:^{
            SRGAnalyticsHiddenEventLabels *labels = [[SRGAnalyticsHiddenEventLabels alloc] init];
            labels.source = notificationContent.notificationInfo[@"show"] ?: AnalyticsSourceNotificationPush;
            labels.type = notificationContent.notificationInfo[@"type"] ?: AnalyticsTypeActionPlayMedia;
            labels.value = mediaURN;
            [SRGAnalyticsTracker.sharedTracker trackHiddenEventWithName:AnalyticsTitleNotificationPushOpen labels:labels];
        }];
    }
    else if (notificationContent.notificationInfo[@"show"]) {
        NSString *showURN = notificationContent.notificationInfo[@"show"];
        UIApplication *application = UIApplication.sharedApplication;
        PlayAppDelegate *appDelegate = (PlayAppDelegate *)application.delegate;
        [appDelegate openShowWithURN:showURN channelUid:channelUid fromPushNotification:YES completionBlock:^{
            SRGAnalyticsHiddenEventLabels *labels = [[SRGAnalyticsHiddenEventLabels alloc] init];
            labels.source = AnalyticsSourceNotificationPush;
            labels.type = notificationContent.notificationInfo[@"type"] ?: AnalyticsTypeActionDisplayShow;
            labels.value = showURN;
            [SRGAnalyticsTracker.sharedTracker trackHiddenEventWithName:AnalyticsTitleNotificationPushOpen labels:labels];
        }];
    }
    else {
        SRGAnalyticsHiddenEventLabels *labels = [[SRGAnalyticsHiddenEventLabels alloc] init];
        labels.source = AnalyticsSourceNotificationPush;
        labels.type = notificationContent.notificationInfo[@"type"] ?: AnalyticsTypeActionNotificationAlert;
        labels.value = notificationContent.alertBody;
        [SRGAnalyticsTracker.sharedTracker trackHiddenEventWithName:AnalyticsTitleNotificationPushOpen labels:labels];
    }
    completionHandler();
}

- (void)receivedForegroundNotification:(UANotificationContent *)notificationContent completionHandler:(void (^)(void))completionHandler
{
    if (@available(iOS 10, *)) {
        if (notificationContent.notification) {
            Notification *notification = [[Notification alloc] initWithNotification:notificationContent.notification];
            [Notification saveNotification:notification read:NO];
        }
    }
    [NSNotificationCenter.defaultCenter postNotificationName:PushServiceDidReceiveNotification object:self];
    completionHandler();
}

- (void)receivedBackgroundNotification:(UANotificationContent *)notificationContent completionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    if (@available(iOS 10, *)) {
        if (notificationContent.notification) {
            Notification *notification = [[Notification alloc] initWithNotification:notificationContent.notification];
            [Notification saveNotification:notification read:NO];
        }
    }
    [NSNotificationCenter.defaultCenter postNotificationName:PushServiceDidReceiveNotification object:self];
    completionHandler(UIBackgroundFetchResultNewData);
}

@end

@implementation PushService (Helpers)

- (BOOL)toggleSubscriptionForShow:(SRGShow *)show
{
    if (! self.enabled || ! show) {
        return NO;
    }
    
    if ([self isSubscribedToShowURN:show.URN]) {
        [self unsubscribeFromShowURNs:[NSSet setWithObject:show.URN]];
    }
    else {
        [self subscribeToShowURNs:[NSSet setWithObject:show.URN]];
    }
    
    return YES;
}

- (BOOL)toggleSubscriptionForShow:(SRGShow *)show inView:(UIView *)view
{
    return [self toggleSubscriptionForShow:show inViewController:view.nearestViewController];
}

- (BOOL)toggleSubscriptionForShow:(SRGShow *)show inViewController:(UIViewController *)viewController
{
    if (! self.enabled) {
        if (! [self presentSystemAlertForPushNotifications]) {
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Enable notifications?", @"Question displayed at the top of an alert asking the user to enable notifications")
                                                                                     message:NSLocalizedString(@"For the application to inform you when a new episode is available, notifications must be enabled.", @"Explanation displayed in the alert asking the user to enable notifications")
                                                                              preferredStyle:UIAlertControllerStyleAlert];
            [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Enable in system settings", @"Title of a button to propose the user to enable notifications in the system settings") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                NSURL *URL = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
                [UIApplication.sharedApplication openURL:URL];
            }]];
            [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"Title of a cancel button") style:UIAlertActionStyleDefault handler:nil]];
            [viewController presentViewController:alertController animated:YES completion:nil];
        }
        return NO;
    }
    else {
        [self toggleSubscriptionForShow:show];
        return YES;
    }
}

@end
