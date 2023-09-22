//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "AppDelegate.h"

#import "ApplicationConfiguration.h"
#import "ApplicationSettings.h"
#import "ApplicationSettingsConstants.h"
#import "Banner.h"
#import "DeepLinkService.h"
#import "Download.h"
#import "Favorites.h"
#import "GoogleCast.h"
#import "NSBundle+PlaySRG.h"
#import "PlayApplication.h"
#import "PlayFirebaseConfiguration.h"
#import "PlayLogger.h"
#import "PlaySRG-Swift.h"
#import "PushService.h"
#import "UpdateInfo.h"

@import AirshipCore;
@import AppCenter;
@import AppCenterCrashes;
@import AppCenterDistribute;
@import AVFoundation;
@import CarPlay;
@import Firebase;
@import Mantle;
@import SRGAnalyticsIdentity;
@import SRGAppearance;
@import SRGDataProvider;
@import SRGIdentity;
@import SRGLetterbox;
@import SRGNetwork;
@import SRGUserData;

static void *s_kvoContext = &s_kvoContext;

@interface AppDelegate() <SRGAnalyticsTrackerDataSource>

@end

@implementation AppDelegate

#pragma mark Application lifecycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary<UIApplicationLaunchOptionsKey,id> *)launchOptions
{
    NSAssert(NSClassFromString(@"ASIdentifierManager") == Nil, @"No implicit AdSupport.framework dependency must be found");
    
    [AVAudioSession.sharedInstance setCategory:AVAudioSessionCategoryPlayback error:NULL];
    [RemoteCommandCenter activateRatingCommand];
    
    PlayApplicationRunOnce(^(void (^completionHandler)(BOOL success)) {
        [PlayFirebaseConfiguration clearFirebaseConfigurationCache];
        completionHandler(YES);
    }, @"FirebaseConfigurationReset");
    
    // The configuration file, copied at build time in the main product bundle, has the standard Firebase
    // configuration filename
    if ([NSBundle.mainBundle pathForResource:@"GoogleService-Info" ofType:@"plist"]) {
        [FIRApp configure];
    }
    
    ApplicationConfiguration *applicationConfiguration = ApplicationConfiguration.sharedApplicationConfiguration;
    DeepLinkService.currentService = [[DeepLinkService alloc] initWithServiceURL:applicationConfiguration.middlewareURL];
    
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
                                           selector:@selector(userConsentWillShowBanner:)
                                               name:UserConsentHelper.userConsentWillShowBannerNotification
                                             object:nil];
    
    [PushService.sharedService setupWithLaunchingWithOptions:launchOptions];
    [PushService.sharedService updateApplicationBadge];
    
    [UserConsentHelper setup];
    [self setupAnalytics];
    
    PlayApplicationRunOnce(^(void (^completionHandler)(BOOL success)) {
        NSUserDefaults *userDefaults = NSUserDefaults.standardUserDefaults;
        [userDefaults removeObjectForKey:PlaySRGSettingServiceIdentifier];
        [userDefaults synchronize];
        completionHandler(YES);
    }, @"DataProviderServiceURLChange");
    
    [self setupDataProvider];
    
    // Use appropriate voice over language for the whole application
    application.accessibilityLanguage = applicationConfiguration.voiceOverLanguageCode;
    
#if defined(DEBUG) || defined(NIGHTLY) || defined(BETA)
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    [defaults addObserver:self forKeyPath:PlaySRGSettingServiceIdentifier options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld  context:s_kvoContext];
    [defaults addObserver:self forKeyPath:PlaySRGSettingUserLocation options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:s_kvoContext];
#endif
    
    // Various setups
#ifndef DEBUG
    [self setupAppCenter];
#endif
    
    // Clean downloaded folder
    [Download removeUnusedDownloadedFiles];
    
    PlayApplicationRunOnce(^(void (^completionHandler)(BOOL success)) {
        [Download updateUnplayableDownloads];
        completionHandler(YES);
    }, @"updateUnplayableDownloads2");
    
    [self checkForForcedUpdates];
    
    __block BOOL firstLaunchDone = YES;
    PlayApplicationRunOnce(^(void (^completionHandler)(BOOL success)) {
        firstLaunchDone = NO;
        completionHandler(YES);
    }, @"FirstLaunchDone");
    
    PlayApplicationRunOnce(^(void (^completionHandler)(BOOL success)) {
        [UIImage srg_clearVectorImageCache];
        completionHandler(YES);
    }, @"ClearVectorImageCache2");
    
    PlayApplicationRunOnce(^(void (^completionHandler)(BOOL success)) {
        NSUserDefaults *userDefaults = NSUserDefaults.standardUserDefaults;
        NSString *previousKey = @"PlaySRGSettingSelectedLiveStreamURNForChannels";
        NSDictionary *value = [userDefaults dictionaryForKey:previousKey];
        [userDefaults setObject:value forKey:PlaySRGSettingSelectedLivestreamURNForChannels];
        [userDefaults removeObjectForKey:previousKey];
        [userDefaults synchronize];
        completionHandler(YES);
    }, @"MigrateSelectedLiveStreamURNForChannels");
    
    FavoritesUpdatePushService();
    
    [NSNotificationCenter.defaultCenter addObserverForName:SRGPreferencesDidChangeNotification object:SRGUserData.currentUserData.preferences queue:nil usingBlock:^(NSNotification * _Nonnull notification) {
        NSSet<NSString *> *domains = notification.userInfo[SRGPreferencesDomainsKey];
        if ([domains containsObject:PlayPreferencesDomain]) {
            FavoritesUpdatePushService();
        }
    }];
    
    return YES;
}

- (UISceneConfiguration *)application:(UIApplication *)application configurationForConnectingSceneSession:(UISceneSession *)connectingSceneSession options:(UISceneConnectionOptions *)options
{
    if (connectingSceneSession.role == CPTemplateApplicationSceneSessionRoleApplication) {
        return [[UISceneConfiguration alloc] initWithName:@"CarPlay" sessionRole:connectingSceneSession.role];
    }
    else {
        return [[UISceneConfiguration alloc] initWithName:@"Default" sessionRole:connectingSceneSession.role];
    }
}

// https://support.urbanairship.com/hc/en-us/articles/213492483-iOS-Badging-and-Auto-Badging
- (void)applicationDidBecomeActive:(UIApplication *)application
{
    [PushService.sharedService updateApplicationBadge];
}

#pragma mark SRGAnalyticsTrackerDataSource protocol

- (SRGAnalyticsLabels *)srg_globalLabels
{
    return SRGAnalyticsLabels.play_globalLabels;
}

#pragma mark Helpers

- (void)setupAppCenter
{
    NSString *appCenterSecret = [NSBundle.mainBundle objectForInfoDictionaryKey:@"AppCenterSecret"];
    if (appCenterSecret.length == 0) {
        return;
    }
    
#if defined(APPCENTER)
    MSACDistribute.updateTrack = MSACUpdateTrackPrivate;
    [MSACAppCenter start:appCenterSecret withServices:@[ MSACCrashes.class, MSACDistribute.class ]];
#else
    [MSACAppCenter start:appCenterSecret withServices:@[ MSACCrashes.class ]];
#endif
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
                                                                                                       sourceKey:applicationConfiguration.analyticsSourceKey
                                                                                                        siteName:applicationConfiguration.siteName];
    [SRGAnalyticsTracker.sharedTracker startWithConfiguration:configuration
                                                   dataSource:self
                                              identityService:SRGIdentityService.currentIdentityService];
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
                
                UIViewController *topViewController = UIApplication.sharedApplication.mainTopViewController;
                [topViewController presentViewController:alertController animated:YES completion:nil];
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
                
                UIViewController *topViewController = UIApplication.sharedApplication.mainTopViewController;
                [topViewController presentViewController:alertController animated:YES completion:nil];
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
    
    UIViewController *topViewController = UIApplication.sharedApplication.mainTopViewController;
    [topViewController presentViewController:productViewController animated:YES completion:nil];
}

#pragma mark SKStoreProductViewControllerDelegate protocol

- (void)productViewControllerDidFinish:(SKStoreProductViewController *)viewController
{
    UIViewController *topViewController = UIApplication.sharedApplication.mainTopViewController;
    [topViewController dismissViewControllerAnimated:YES completion:^{
        [self checkForForcedUpdates];
    }];
}

#pragma mark Notifications

- (void)playbackDidContinueAutomatically:(NSNotification *)notification
{
    SRGMedia *media = notification.userInfo[SRGLetterboxMediaKey];
    if (media) {
        [[AnalyticsEventObjC continuousPlaybackWithAction:AnalyticsContiniousPlaybackActionPlayAutomatic
                                                       mediaUrn:media.URN]
         send];
    }
}

- (void)userConsentWillShowBanner:(NSNotification *)notification
{
    [SRGLetterboxService.sharedService.controller pause];
}

- (void)userDidCancelLogin:(NSNotification *)notification
{
    [[AnalyticsEventObjC identityWithAction:AnalyticsIdentityActionCancelLogin] send];
}

- (void)userDidLogin:(NSNotification *)notification
{
    [[AnalyticsEventObjC identityWithAction:AnalyticsIdentityActionLogin] send];
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
                           sticky:YES];
        });
    }
    
    AnalyticsIdentityAction action = unexpectedLogout ? AnalyticsIdentityActionUnexpectedLogout : AnalyticsIdentityActionLogout;
    [[AnalyticsEventObjC identityWithAction:action] send];
}

#pragma mark KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (s_kvoContext == context) {
        if ([keyPath isEqualToString:PlaySRGSettingServiceIdentifier] || [keyPath isEqualToString:PlaySRGSettingUserLocation]) {
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
            }
        }
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

@end
