//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SettingsViewController.h"

#import "PlayAppDelegate.h"
#import "ApplicationConfiguration.h"
#import "ApplicationSettings.h"
#import "Banner.h"
#import "Download.h"
#import "Favorites.h"
#import "History.h"
#import "NSBundle+PlaySRG.h"
#import "NSDateFormatter+PlaySRG.h"
#import "Onboarding.h"
#import "PushService.h"
#import "UIApplication+PlaySRG.h"
#import "UIImage+PlaySRG.h"
#import "UIViewController+PlaySRG.h"
#import "WebViewController.h"

#import <FLEX/FLEX.h>
#import <HockeySDK/HockeySDK.h>
#import <InAppSettingsKit/IASKSettingsReader.h>
#import <libextobjc/libextobjc.h>
#import <SafariServices/SafariServices.h>
#import <SRGAppearance/SRGAppearance.h>
#import <SRGUserData/SRGUserData.h>
#import <SRGIdentity/SRGIdentity.h>
#import <SRGLetterbox/SRGLetterbox.h>
#import <YYWebImage/YYWebImage.h>

// Public settings
static NSString * const SettingsFeaturesButton = @"Button_Features";
static NSString * const SettingsWhatsNewButton = @"Button_WhatsNew";
static NSString * const SettingsTermsAndConditionsButton = @"Button_TermsAndConditions";
static NSString * const SettingsDataProtectionButton = @"Button_DataProtection";
static NSString * const SettingsBetaTestingButton = @"Button_BetaTesting";
static NSString * const SettingsSourceCodeButton = @"Button_Source code";

// Playback settings group
static NSString * const SettingsPlaybackGroup = @"Group_Playback";

// Information group
static NSString * const SettingsInformationGroup = @"Group_Information";

// Advanced features settings group
static NSString * const SettingsAdvancedFeaturesGroup = @"Group_AdvancedFeatures";
static NSString * const SettingsServerSettingsButton = @"Button_ServerSettings";
static NSString * const SettingsUserLocationSettingsButton = @"Button_UserLocationSettings";
static NSString * const SettingsCheckForUpdatesButton = @"Button_CheckForUpdates";
static NSString * const SettingsInstallPreviousVersionButton = @"Button_InstallPreviousVersion";
static NSString * const SettingsSubscribeToAllShowsButton = @"Button_SubscribeToAllShows";
static NSString * const SettingsSystemSettingsButton = @"Button_SystemSettings";

// Reset group
static NSString * const SettingsResetGroup = @"Group_Reset";
static NSString * const SettingsClearWebCacheButton = @"Button_ClearWebCache";
static NSString * const SettingsClearVectorImageCacheButton = @"Button_ClearVectorImageCache";
static NSString * const SettingsClearAllContentsButton = @"Button_ClearAllContents";

// Developer settings group
static NSString * const SettingsDeveloperGroup = @"Group_Developer";
static NSString * const SettingsFLEXButton = @"Button_FLEX";

// ** Private SRGLetterbox setter for DRM slow rollout.
// TODO: Remove in 2019

@interface SRGLetterboxController (Private_SRGLetterbox)

@property (class, nonatomic) BOOL prefersDRM;

@end

// **

@interface SettingsViewController () <SFSafariViewControllerDelegate>

@property (nonatomic) SRGRequestQueue *requestQueue;

@end

@implementation SettingsViewController

#pragma mark View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"Settings", nil);
    
    [self updateSettingsVisibility];
    
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(settingDidChange:)
                                               name:kIASKAppSettingChanged
                                             object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(applicationConfigurationDidChange:)
                                               name:ApplicationConfigurationDidChangeNotification
                                             object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(didUpdateAccount:)
                                               name:SRGIdentityServiceDidUpdateAccountNotification
                                             object:SRGIdentityService.currentIdentityService];
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(userDidLogout:)
                                               name:SRGIdentityServiceUserDidLogoutNotification
                                             object:SRGIdentityService.currentIdentityService];
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(userDataDidFinishSynchronization:)
                                               name:SRGUserDataDidStartSynchronizationNotification
                                             object:SRGUserData.currentUserData];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    // Apply settings on exit
    if ([self play_isMovingFromParentViewController]) {
        SRGLetterboxService.sharedService.mirroredOnExternalScreen = ApplicationSettingPresenterModeEnabled();
    }
}

#pragma mark IASKSettingsDelegate protocol

- (void)settingsViewController:(IASKAppSettingsViewController *)sender buttonTappedForSpecifier:(IASKSpecifier *)specifier
{
    if ([specifier.key isEqualToString:SettingsWhatsNewButton]) {
        PlayAppDelegate *appDelegate = (PlayAppDelegate *)UIApplication.sharedApplication.delegate;
        [appDelegate loadWhatsNewWithCompletionHandler:^(UIViewController * _Nullable viewController, NSError * _Nullable error) {
            if (error) {
                [Banner showError:error inViewController:self];
                return;
            }
            
            viewController.title = NSLocalizedString(@"What's new", @"Title displayed at the top of the What's new view");
            [self.navigationController pushViewController:viewController animated:YES];
        }];
    }
    else if ([specifier.key isEqualToString:SettingsTermsAndConditionsButton]) {
        NSURL *termsAndConditionsURL = ApplicationConfiguration.sharedApplicationConfiguration.termsAndConditionsURL;
        NSAssert(termsAndConditionsURL, @"Button must not be displayed if no Terms and conditions URL has been specified");
        
        NSURLRequest *request = [NSURLRequest requestWithURL:termsAndConditionsURL];
        WebViewController *webViewController = [[WebViewController alloc] initWithRequest:request customizationBlock:nil decisionHandler:nil analyticsPageType:AnalyticsPageTypeSystem];
        webViewController.title = PlaySRGSettingsLocalizedString(@"Terms and conditions", @"Title displayed at the top of the Terms and conditions view");
        webViewController.tracked = NO;            // The website we display is already tracked.
        [self.navigationController pushViewController:webViewController animated:YES];
    }
    else if ([specifier.key isEqualToString:SettingsDataProtectionButton]) {
        NSURL *dataProtectionURL = ApplicationConfiguration.sharedApplicationConfiguration.dataProtectionURL;
        NSAssert(dataProtectionURL, @"Button must not be displayed if no data protection URL has been specified");
        
        NSURLRequest *request = [NSURLRequest requestWithURL:dataProtectionURL];
        WebViewController *webViewController = [[WebViewController alloc] initWithRequest:request customizationBlock:nil decisionHandler:nil analyticsPageType:AnalyticsPageTypeSystem];
        webViewController.title = PlaySRGSettingsLocalizedString(@"Data protection", @"Title displayed at the top of the data protection view");
        webViewController.tracked = NO;            // The website we display is already tracked.
        [self.navigationController pushViewController:webViewController animated:YES];
    }
    else if ([specifier.key isEqualToString:SettingsBetaTestingButton]) {
        NSURL *betaTestingURL = ApplicationConfiguration.sharedApplicationConfiguration.betaTestingURL;
        NSAssert(betaTestingURL, @"Button must not be displayed if no beta testing URL has been specified");
        
        [UIApplication.sharedApplication play_openURL:betaTestingURL withCompletionHandler:nil];
    }
    else if ([specifier.key isEqualToString:SettingsSourceCodeButton]) {
        NSURL *sourceCodeURL = ApplicationConfiguration.sharedApplicationConfiguration.sourceCodeURL;
        NSAssert(sourceCodeURL, @"Button must not be displayed if no source code URL has been specified");
        
        [UIApplication.sharedApplication play_openURL:sourceCodeURL withCompletionHandler:nil];
    }
    else if ([specifier.key isEqualToString:SettingsCheckForUpdatesButton]) {
        [[BITHockeyManager sharedHockeyManager].updateManager showUpdateView];
    }
    else if ([specifier.key isEqualToString:SettingsInstallPreviousVersionButton]) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Previous versions", @"Message title displayed when the user wants to install a previous version")
                                                                                 message:NSLocalizedString(@"You may have to uninstall the application if the restored version crashes at launch.\n\nPrevious versions can be found under the \"History\" tab on the next screen.", @"Message description displayed when the user wants to install a previous version")
                                                                          preferredStyle:UIAlertControllerStyleAlert];
        [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"I understand", @"Title of the button to install a previous version") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            NSString *hockeyIdentifier = [NSBundle.mainBundle objectForInfoDictionaryKey:@"HockeyIdentifier"];
            NSString *stringURL = [NSString stringWithFormat:@"https://rink.hockeyapp.net/apps/%@", hockeyIdentifier];
            SFSafariViewController *safariViewController = [[SFSafariViewController alloc] initWithURL:[NSURL URLWithString:stringURL]];
            safariViewController.modalPresentationStyle = UIModalPresentationOverFullScreen;
            safariViewController.modalPresentationCapturesStatusBarAppearance = YES;
            safariViewController.delegate = self;
            [self presentViewController:safariViewController animated:YES completion:nil];
        }]];
        [self presentViewController:alertController animated:YES completion:nil];
    }
    else if ([specifier.key isEqualToString:SettingsSubscribeToAllShowsButton]) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Automatic subscriptions", @"Message title displayed when subscribing to all TV and radio shows")
                                                                                 message:NSLocalizedString(@"Subscribing to all TV and radio shows…", @"Message description displayed when subscribing to all TV and radio shows")
                                                                          preferredStyle:UIAlertControllerStyleAlert];
        [self presentViewController:alertController animated:YES completion:nil];
        
        @weakify(self)
        self.requestQueue = [[SRGRequestQueue alloc] initWithStateChangeBlock:^(BOOL finished, NSError * _Nullable error) {
            @strongify(self)
            
            if (finished) {
                [self dismissViewControllerAnimated:YES completion:^{
                    NSString *message = error ? NSLocalizedString(@"Automatic subscriptions failed. Please retry.", @"Message description displayed when the user could not be subscribed to all TV and radio shows") : NSLocalizedString(@"Subscribed to all TV and radio shows.", @"Message description displayed when the user was subscribed to all TV and radio shows");
                    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Automatic subscriptions", @"Message title displayed when the user subscribed to all TV and radio shows")
                                                                                             message:message
                                                                                      preferredStyle:UIAlertControllerStyleAlert];
                    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"Title of the button when the user subscribed to all TV and radio shows") style:UIAlertActionStyleDefault handler:NULL]];
                    [self presentViewController:alertController animated:YES completion:nil];
                }];
            }
        }];
        
        ApplicationConfiguration *applicationConfiguration = ApplicationConfiguration.sharedApplicationConfiguration;
        SRGVendor vendor = applicationConfiguration.vendor;
        
        SRGPageRequest *tvRequest = [[SRGDataProvider.currentDataProvider tvShowsForVendor:vendor withCompletionBlock:^(NSArray<SRGShow *> * _Nullable shows, SRGPage * _Nonnull page, SRGPage * _Nullable nextPage, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
            @strongify(self)
            
            [self.requestQueue reportError:error];
            [shows enumerateObjectsUsingBlock:^(SRGShow * _Nonnull show, NSUInteger idx, BOOL * _Nonnull stop) {
                if (! FavoritesIsSubscribedToShow(show)) {
                    FavoritesAddShow(show);
                    FavoritesToggleSubscriptionForShow(show, nil);
                }
            }];
        }] requestWithPageSize:SRGDataProviderUnlimitedPageSize];
        [self.requestQueue addRequest:tvRequest resume:YES];
        
        for (RadioChannel *radioChannel in applicationConfiguration.radioChannels) {
            SRGPageRequest *radioRequest = [[SRGDataProvider.currentDataProvider radioShowsForVendor:vendor channelUid:radioChannel.uid withCompletionBlock:^(NSArray<SRGShow *> * _Nullable shows, SRGPage * _Nonnull page, SRGPage * _Nullable nextPage, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
                @strongify(self)
                
                [self.requestQueue reportError:error];
                [shows enumerateObjectsUsingBlock:^(SRGShow * _Nonnull show, NSUInteger idx, BOOL * _Nonnull stop) {
                    if (! FavoritesIsSubscribedToShow(show)) {
                        FavoritesAddShow(show);
                        FavoritesToggleSubscriptionForShow(show, nil);
                    }
                }];
            }] requestWithPageSize:SRGDataProviderUnlimitedPageSize];
            [self.requestQueue addRequest:radioRequest resume:YES];
        }
    }
    else if ([specifier.key isEqualToString:SettingsSystemSettingsButton]) {
        NSURL *URL = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
        [UIApplication.sharedApplication openURL:URL];
    }
    else if ([specifier.key isEqualToString:SettingsClearWebCacheButton]) {
        [self clearWebCache];
    }
    else if ([specifier.key isEqualToString:SettingsClearVectorImageCacheButton]) {
        [UIImage srg_clearVectorImageCache];
    }
    else if ([specifier.key isEqualToString:SettingsClearAllContentsButton]) {
        [self clearWebCache];
        [UIImage srg_clearVectorImageCache];
        [Download removeAllDownloads];
    }
#if defined(DEBUG) || defined(NIGHTLY) || defined(BETA)
    else if ([specifier.key isEqualToString:SettingsFLEXButton]) {
        [[FLEXManager sharedManager] toggleExplorer];
    }
#endif
}

- (NSString *)settingsViewController:(id<IASKViewController>)settingsViewController tableView:(UITableView *)tableView titleForFooterForSection:(NSInteger)section
{
    NSString *key = [settingsViewController.settingsReader keyForSection:section];
    if ([key isEqualToString:SettingsInformationGroup]) {
        if (SRGIdentityService.currentIdentityService.isLoggedIn) {
            NSDate *synchronizationDate = SRGUserData.currentUserData.user.synchronizationDate;
            NSString *dateString = synchronizationDate ? [NSDateFormatter.play_relativeDateAndTimeFormatter stringFromDate:synchronizationDate] : NSLocalizedString(@"Never", @"Text displayed when no data synchronization has been made yet");
            return [NSString stringWithFormat:NSLocalizedString(@"Last synchronization: %@", @"Introductory text for the most recent data synchronization date"), dateString];
        }
        return nil;
    }
#if defined(DEBUG) || defined(NIGHTLY) || defined(BETA)
    else if ([key isEqualToString:SettingsAdvancedFeaturesGroup]) {
        IASKSpecifier *specifier = [settingsViewController.settingsReader specifierForKey:SettingsAdvancedFeaturesGroup];
        NSString *prefersDRMState = SRGLetterboxController.prefersDRM ? PlaySRGNonLocalizedString(@"ON") : PlaySRGNonLocalizedString(@"OFF");
        NSString *prefersDRMText = [NSString stringWithFormat:NSLocalizedString(@"Prefers DRM streams: %@.", @"Introductory text for DRM status information in the app settings"), prefersDRMState];
        return (specifier.footerText.length != 0) ? [specifier.footerText stringByAppendingFormat:@"\n\n%@", prefersDRMText] : prefersDRMText;
    }
#endif
    else {
        return nil;
    }
}

#pragma mark Helpers

- (void)clearWebCache
{
    [[NSURLCache sharedURLCache] removeAllCachedResponses];
    
    YYImageCache *cache = YYWebImageManager.sharedManager.cache;
    [cache.memoryCache removeAllObjects];
    [cache.diskCache removeAllObjects];
}

- (void)updateSettingsVisibility
{
    NSMutableArray *hiddenKeys = [NSMutableArray array];
    
#if !defined(DEBUG) && !defined(NIGHTLY) && !defined(BETA)
    [hiddenKeys addObject:SettingsAdvancedFeaturesGroup];
    [hiddenKeys addObject:SettingsServerSettingsButton];
    [hiddenKeys addObject:SettingsUserLocationSettingsButton];
    [hiddenKeys addObject:PlaySRGSettingPresenterModeEnabled];
    [hiddenKeys addObject:PlaySRGSettingStandaloneEnabled];
    [hiddenKeys addObject:PlaySRGSettingOriginalImagesOnlyEnabled];
    [hiddenKeys addObject:PlaySRGSettingAlternateRadioHomepageDesignEnabled];
    [hiddenKeys addObject:SettingsCheckForUpdatesButton];
    [hiddenKeys addObject:SettingsInstallPreviousVersionButton];
    [hiddenKeys addObject:SettingsSubscribeToAllShowsButton];
    [hiddenKeys addObject:SettingsSystemSettingsButton];
    [hiddenKeys addObject:SettingsResetGroup];
    [hiddenKeys addObject:SettingsClearWebCacheButton];
    [hiddenKeys addObject:SettingsClearVectorImageCacheButton];
    [hiddenKeys addObject:SettingsClearAllContentsButton];
    
    [hiddenKeys addObject:SettingsDeveloperGroup];
    [hiddenKeys addObject:SettingsFLEXButton];
#else
    if (! [BITHockeyManager sharedHockeyManager].updateManager) {
        [hiddenKeys addObject:SettingsCheckForUpdatesButton];
        [hiddenKeys addObject:SettingsInstallPreviousVersionButton];
    }
    
    if (! PushService.sharedService.enabled) {
        [hiddenKeys addObject:SettingsSubscribeToAllShowsButton];
    }
#endif
    
    ApplicationConfiguration *applicationConfiguration = ApplicationConfiguration.sharedApplicationConfiguration;
    if (! applicationConfiguration.continuousPlaybackAvailable) {
        [hiddenKeys addObject:SettingsPlaybackGroup];
        [hiddenKeys addObject:PlaySRGSettingAutoplayEnabled];
    }
    
    if (Onboarding.onboardings.count == 0) {
        [hiddenKeys addObject:SettingsFeaturesButton];
    }
    
    if (! applicationConfiguration.termsAndConditionsURL) {
        [hiddenKeys addObject:SettingsTermsAndConditionsButton];
    }
    
    if (! applicationConfiguration.dataProtectionURL) {
        [hiddenKeys addObject:SettingsDataProtectionButton];
    }
    
    if (! applicationConfiguration.betaTestingURL) {
        [hiddenKeys addObject:SettingsBetaTestingButton];
    }
    
    if (! applicationConfiguration.sourceCodeURL) {
        [hiddenKeys addObject:SettingsSourceCodeButton];
    }
    
    self.hiddenKeys = [hiddenKeys copy];
}

#pragma mark SRGAnalyticsViewTracking protocol

- (NSArray<NSString *> *)srg_pageViewLevels
{
    return @[ AnalyticsNameForPageType(AnalyticsPageTypeSystem) ];
}

- (NSString *)srg_pageViewTitle
{
    return self.title;
}

#pragma mark Notifications

- (void)settingDidChange:(NSNotification *)notification
{
    NSNumber *originalImagesOnlyEnabled = notification.userInfo[PlaySRGSettingOriginalImagesOnlyEnabled];
    if (originalImagesOnlyEnabled) {
        [UIImage play_setUseOriginalImagesOnly:originalImagesOnlyEnabled.boolValue];
    }
    
    NSNumber *presenterModeEnabled = notification.userInfo[PlaySRGSettingPresenterModeEnabled];
    if (presenterModeEnabled) {
        SRGLetterboxService.sharedService.mirroredOnExternalScreen = presenterModeEnabled.boolValue;
    }
}

- (void)applicationConfigurationDidChange:(NSNotification *)notification
{
    [self updateSettingsVisibility];
}

- (void)didUpdateAccount:(NSNotification *)notification
{
    [self.tableView reloadData];
}

- (void)userDidLogout:(NSNotification *)notification
{
    [self.tableView reloadData];
}

- (void)userDataDidFinishSynchronization:(NSNotification *)notification
{
    [self.tableView reloadData];
}

#pragma mark SFSafariViewControllerDelegate

- (void)safariViewControllerDidFinish:(SFSafariViewController *)controller
{
    [controller dismissViewControllerAnimated:YES completion:nil];
}

@end
