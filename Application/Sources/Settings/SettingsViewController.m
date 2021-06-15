//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SettingsViewController.h"

#import "AnalyticsConstants.h"
#import "ApplicationConfiguration.h"
#import "ApplicationSettings.h"
#import "ApplicationSettingsConstants.h"
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
#import "UIWindow+PlaySRG.h"
#import "WebViewController.h"

#import <InAppSettingsKit/IASKSettingsReader.h>

@import AppCenterDistribute;
@import FLEX;
@import libextobjc;
@import SafariServices;
@import SRGAppearance;
@import SRGDataProviderNetwork;
@import SRGUserData;
@import SRGIdentity;
@import SRGLetterbox;
@import YYWebImage;

// Autoplay group
static NSString * const SettingsAutoplayGroup = @"Group_Autoplay";

// Display group
static NSString * const SettingsDisplayGroup = @"Group_Display";

// Permissions group
static NSString * const SettingsPermissionsGroup = @"Group_Permissions";
static NSString * const SettingsSystemSettingsButton = @"Button_SystemSettings";

// Information group
static NSString * const SettingsInformationGroup = @"Group_Information";
static NSString * const SettingsFeaturesButton = @"Button_Features";
static NSString * const SettingsWhatsNewButton = @"Button_WhatsNew";
static NSString * const SettingsTermsAndConditionsButton = @"Button_TermsAndConditions";
static NSString * const SettingsHelpAndCopyrightButton = @"Button_HelpAndCopyright";
static NSString * const SettingsDataProtectionButton = @"Button_DataProtection";
static NSString * const SettingsFeedbackButton = @"Button_Feedback";
static NSString * const SettingsSourceCodeButton = @"Button_SourceCode";
static NSString * const SettingsBetaTestingButton = @"Button_BetaTesting";
static NSString * const SettingsApplicationVersionCell = @"Cell_ApplicationVersion";

// Advanced features settings group
static NSString * const SettingsAdvancedFeaturesGroup = @"Group_AdvancedFeatures";
static NSString * const SettingsServerSettingsButton = @"Button_ServerSettings";
static NSString * const SettingsUserLocationSettingsButton = @"Button_UserLocationSettings";
static NSString * const SettingsVersionsAndReleaseNotes = @"Button_VersionsAndReleaseNotes";
static NSString * const SettingsSubscribeToAllShowsButton = @"Button_SubscribeToAllShows";

// Reset group
static NSString * const SettingsResetGroup = @"Group_Reset";
static NSString * const SettingsClearWebCacheButton = @"Button_ClearWebCache";
static NSString * const SettingsClearVectorImageCacheButton = @"Button_ClearVectorImageCache";
static NSString * const SettingsClearAllContentsButton = @"Button_ClearAllContents";

// Developer settings group
static NSString * const SettingsDeveloperGroup = @"Group_Developer";
static NSString * const SettingsFLEXButton = @"Button_FLEX";

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
    
    if (self.navigationController.viewControllers.firstObject == self) {
        UIBarButtonItem *closeBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"close-22"]
                                                                 landscapeImagePhone:nil
                                                                               style:UIBarButtonItemStyleDone
                                                                              target:self
                                                                              action:@selector(close:)];
        closeBarButtonItem.accessibilityLabel = PlaySRGAccessibilityLocalizedString(@"Close", @"Close button label on settings view");
        self.navigationItem.leftBarButtonItem = closeBarButtonItem;
    }
    
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
    [hiddenKeys addObject:SettingsVersionsAndReleaseNotes];
    [hiddenKeys addObject:SettingsSubscribeToAllShowsButton];
    [hiddenKeys addObject:SettingsResetGroup];
    [hiddenKeys addObject:SettingsClearWebCacheButton];
    [hiddenKeys addObject:SettingsClearVectorImageCacheButton];
    [hiddenKeys addObject:SettingsClearAllContentsButton];
    
    [hiddenKeys addObject:SettingsDeveloperGroup];
    [hiddenKeys addObject:SettingsFLEXButton];
#else
    if (! MSACDistribute.isEnabled) {
        [hiddenKeys addObject:SettingsVersionsAndReleaseNotes];
    }
    
    if (! PushService.sharedService.enabled) {
        [hiddenKeys addObject:SettingsSubscribeToAllShowsButton];
    }
#endif
    
    ApplicationConfiguration *applicationConfiguration = ApplicationConfiguration.sharedApplicationConfiguration;
    if (! applicationConfiguration.continuousPlaybackAvailable) {
        [hiddenKeys addObject:SettingsAutoplayGroup];
        [hiddenKeys addObject:PlaySRGSettingAutoplayEnabled];
    }
    
    if (applicationConfiguration.subtitleAvailabilityHidden) {
        [hiddenKeys addObject:PlaySRGSettingSubtitleAvailabilityDisplayed];
    }
    
    if (applicationConfiguration.audioDescriptionAvailabilityHidden) {
        [hiddenKeys addObject:PlaySRGSettingAudioDescriptionAvailabilityDisplayed];
    }
    
    if (applicationConfiguration.subtitleAvailabilityHidden && applicationConfiguration.audioDescriptionAvailabilityHidden) {
        [hiddenKeys addObject:SettingsDisplayGroup];
    }
    
    if (Onboarding.onboardings.count == 0) {
        [hiddenKeys addObject:SettingsFeaturesButton];
    }
    
    if (! applicationConfiguration.impressumURL) {
        [hiddenKeys addObject:SettingsHelpAndCopyrightButton];
    }
    
    if (! applicationConfiguration.termsAndConditionsURL) {
        [hiddenKeys addObject:SettingsTermsAndConditionsButton];
    }
    
    if (! applicationConfiguration.dataProtectionURL) {
        [hiddenKeys addObject:SettingsDataProtectionButton];
    }
    
    if (! applicationConfiguration.feedbackURL) {
        [hiddenKeys addObject:SettingsFeedbackButton];
    }
    
    if (! applicationConfiguration.sourceCodeURL) {
        [hiddenKeys addObject:SettingsSourceCodeButton];
    }
    
    if (! applicationConfiguration.betaTestingURL) {
        [hiddenKeys addObject:SettingsBetaTestingButton];
    }
    
    self.hiddenKeys = hiddenKeys.copy;
}

#pragma mark What's new

/**
 *  Load what's new information, calling the completion handler on completion. The caller is responsible of displaying the
 *  view controller received in case of success.
 */
- (void)loadWhatsNewWithCompletionHandler:(void (^)(UIViewController * _Nullable, NSError * _Nullable))completionHandler
{
    NSURL *whatsNewURL = ApplicationConfiguration.sharedApplicationConfiguration.whatsNewURL;
    [[SRGRequest objectRequestWithURLRequest:[NSURLRequest requestWithURL:whatsNewURL] session:NSURLSession.sharedSession parser:^id _Nullable(NSData * _Nonnull data, NSError * _Nullable __autoreleasing * _Nullable pError) {
        // FIXME: Ugly. Since we are using Pastebin, the missing html extension makes the page load incorrectly. We should:
        //   1) Replace Pastebin
        //   2) Load the what's new URL in the WebViewController directly
        NSString *temporaryFileName = [NSUUID.UUID.UUIDString stringByAppendingPathExtension:@"html"];
        NSString *temporaryFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:temporaryFileName];
        NSURL *temporaryFileURL = [NSURL fileURLWithPath:temporaryFilePath];
        [data writeToURL:temporaryFileURL atomically:YES];
        
        NSString *shortVersionString = [[NSBundle.mainBundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"] componentsSeparatedByString:@"-"].firstObject;
        NSURLComponents *components = [[NSURLComponents alloc] initWithURL:temporaryFileURL resolvingAgainstBaseURL:NO];
        components.queryItems = @[ [[NSURLQueryItem alloc] initWithName:@"build" value:[NSBundle.mainBundle objectForInfoDictionaryKey:@"CFBundleVersion"]],
                                   [[NSURLQueryItem alloc] initWithName:@"version" value:shortVersionString],
                                   [[NSURLQueryItem alloc] initWithName:@"ios" value:UIDevice.currentDevice.systemVersion] ];
        
        return components.URL;
    } completionBlock:^(NSURL * _Nullable URL, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            completionHandler(nil, error);
            return;
        }
        
        NSURLRequest *request = [NSURLRequest requestWithURL:URL];
        WebViewController *webViewController = [[WebViewController alloc] initWithRequest:request customizationBlock:nil decisionHandler:nil];
        webViewController.analyticsPageLevels = @[ AnalyticsPageLevelPlay, AnalyticsPageLevelApplication ];
        webViewController.analyticsPageTitle = AnalyticsPageTitleWhatsNew;
        
        completionHandler(webViewController, nil);
    }] resume];
}

#pragma mark IASKSettingsDelegate protocol

- (void)settingsViewController:(IASKAppSettingsViewController *)settingsViewController buttonTappedForSpecifier:(IASKSpecifier *)specifier
{
    if ([specifier.key isEqualToString:SettingsSystemSettingsButton]) {
        NSURL *URL = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
        [UIApplication.sharedApplication openURL:URL options:@{} completionHandler:nil];
    }
    else if ([specifier.key isEqualToString:SettingsWhatsNewButton]) {
        [self loadWhatsNewWithCompletionHandler:^(UIViewController * _Nullable viewController, NSError * _Nullable error) {
            if (error) {
                [Banner showError:error inViewController:self];
                return;
            }
            
            viewController.title = NSLocalizedString(@"What's new", @"Title displayed at the top of the What's new view");
            [self.navigationController pushViewController:viewController animated:YES];
        }];
    }
    else if ([specifier.key isEqualToString:SettingsHelpAndCopyrightButton]) {
        NSURL *helpAndCopyrightURL = ApplicationConfiguration.sharedApplicationConfiguration.impressumURL;
        NSAssert(helpAndCopyrightURL, @"Button must not be displayed if no Impressum URL has been specified");
        [UIApplication.sharedApplication play_openURL:helpAndCopyrightURL withCompletionHandler:nil];
    }
    else if ([specifier.key isEqualToString:SettingsTermsAndConditionsButton]) {
        NSURL *termsAndConditionsURL = ApplicationConfiguration.sharedApplicationConfiguration.termsAndConditionsURL;
        NSAssert(termsAndConditionsURL, @"Button must not be displayed if no Terms and conditions URL has been specified");
        [UIApplication.sharedApplication play_openURL:termsAndConditionsURL withCompletionHandler:nil];
    }
    else if ([specifier.key isEqualToString:SettingsDataProtectionButton]) {
        NSURL *dataProtectionURL = ApplicationConfiguration.sharedApplicationConfiguration.dataProtectionURL;
        NSAssert(dataProtectionURL, @"Button must not be displayed if no data protection URL has been specified");
        [UIApplication.sharedApplication play_openURL:dataProtectionURL withCompletionHandler:nil];
    }
    else if ([specifier.key isEqualToString:SettingsFeedbackButton]) {
        NSURL *feedbackURL = ApplicationConfiguration.sharedApplicationConfiguration.feedbackURL;
        NSAssert(feedbackURL, @"Button must not be displayed if no feedback URL has been specified");
        
        NSMutableArray *queryItems = [NSMutableArray array];
        [queryItems addObject:[NSURLQueryItem queryItemWithName:@"platform" value:@"iOS"]];
        
        NSString *appVersion = [NSBundle.mainBundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
        [queryItems addObject:[NSURLQueryItem queryItemWithName:@"version" value:appVersion]];
        
        BOOL isPad = UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad;
        [queryItems addObject:[NSURLQueryItem queryItemWithName:@"type" value:isPad ? @"tablet" : @"phone"]];
        [queryItems addObject:[NSURLQueryItem queryItemWithName:@"model" value:UIDevice.currentDevice.model]];
        
        NSString *tagCommanderUid = [NSUserDefaults.standardUserDefaults stringForKey:@"tc_unique_id"];
        if (tagCommanderUid) {
            [queryItems addObject:[NSURLQueryItem queryItemWithName:@"cid" value:tagCommanderUid]];
        }
        
        NSURLComponents *URLComponents = [NSURLComponents componentsWithURL:feedbackURL resolvingAgainstBaseURL:NO];
        URLComponents.queryItems = queryItems.copy;
        
        NSURLRequest *request = [NSURLRequest requestWithURL:URLComponents.URL];
        WebViewController *webViewController = [[WebViewController alloc] initWithRequest:request customizationBlock:^(WKWebView *webView) {
            webView.scrollView.scrollEnabled = NO;
        } decisionHandler:nil];
        webViewController.title = PlaySRGSettingsLocalizedString(@"Your feedback", @"Title displayed at the top of the feedback view");
        webViewController.analyticsPageLevels = @[ AnalyticsPageLevelPlay, AnalyticsPageLevelUser ];
        webViewController.analyticsPageTitle = AnalyticsPageTitleFeedback;
        [self.navigationController pushViewController:webViewController animated:YES];
    }
    else if ([specifier.key isEqualToString:SettingsSourceCodeButton]) {
        NSURL *sourceCodeURL = ApplicationConfiguration.sharedApplicationConfiguration.sourceCodeURL;
        NSAssert(sourceCodeURL, @"Button must not be displayed if no source code URL has been specified");
        [UIApplication.sharedApplication play_openURL:sourceCodeURL withCompletionHandler:nil];
    }
    else if ([specifier.key isEqualToString:SettingsBetaTestingButton]) {
        NSURL *betaTestingURL = ApplicationConfiguration.sharedApplicationConfiguration.betaTestingURL;
        NSAssert(betaTestingURL, @"Button must not be displayed if no beta testing URL has been specified");
        [UIApplication.sharedApplication play_openURL:betaTestingURL withCompletionHandler:nil];
    }
    else if ([specifier.key isEqualToString:SettingsVersionsAndReleaseNotes]) {
        // Clear internal App Center timestamp to force a new update request
        [NSUserDefaults.standardUserDefaults removeObjectForKey:@"MSAppCenterPostponedTimestamp"];
        [MSACDistribute checkForUpdate];
        
        // Display version history
        NSString *appCenterURLString = [NSBundle.mainBundle.infoDictionary objectForKey:@"AppCenterURL"];
        NSURL *appCenterURL = (appCenterURLString.length > 0) ? [NSURL URLWithString:appCenterURLString] : nil;
        if (appCenterURL) {
            SFSafariViewController *safariViewController = [[SFSafariViewController alloc] initWithURL:appCenterURL];
            UIViewController *topViewController = UIApplication.sharedApplication.delegate.window.play_topViewController;
            [topViewController presentViewController:safariViewController animated:YES completion:nil];
        }
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

- (NSString *)settingsViewController:(UITableViewController<IASKViewController> *)settingsViewController titleForFooterInSection:(NSInteger)section specifier:(IASKSpecifier *)specifier
{
    NSString *key = [settingsViewController.settingsReader keyForSection:section];
    if ([key isEqualToString:SettingsInformationGroup]) {
        if (SRGIdentityService.currentIdentityService.isLoggedIn) {
            NSDate *synchronizationDate = SRGUserData.currentUserData.user.synchronizationDate;
            NSString *dateString = synchronizationDate ? [NSDateFormatter.play_relativeDateAndTimeFormatter stringFromDate:synchronizationDate] : NSLocalizedString(@"Never", @"Text displayed when no data synchronization has been made yet");
            return [NSString stringWithFormat:NSLocalizedString(@"Last synchronization: %@", @"Introductory text for the most recent data synchronization date"), dateString];
        }
        else {
            return nil;
        }
    }
    else if ([key isEqualToString:SettingsPermissionsGroup]) {
        return NSLocalizedString(@"Local network access must be allowed for Google Cast receiver discovery.", @"Setting footer message for system permission group. New rule for iOS 14 and more.");
    }
    else {
        return nil;
    }
}

- (CGFloat)settingsViewController:(UITableViewController<IASKViewController> *)settingsViewController heightForSpecifier:(IASKSpecifier *)specifier
{
    if ([specifier.key isEqualToString:SettingsApplicationVersionCell]) {
        return 44.f;
    }
    else {
        return 0.f;
    }
}

- (UITableViewCell *)settingsViewController:(UITableViewController<IASKViewController> *)settingsViewController cellForSpecifier:(IASKSpecifier *)specifier
{
    if ([specifier.key isEqualToString:SettingsApplicationVersionCell]) {
        static NSString * const kApplicationVersionCellIdentifier = @"Cell_ApplicationVersion";
        UITableViewCell *cell = [settingsViewController.tableView dequeueReusableCellWithIdentifier:kApplicationVersionCellIdentifier];
        if (! cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:kApplicationVersionCellIdentifier];
        }
        cell.textLabel.text = specifier.title;
        cell.detailTextLabel.text = NSBundle.mainBundle.play_friendlyVersionNumber;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        return cell;
    }
    else {
        return nil;
    }
}

#pragma mark SRGAnalyticsViewTracking protocol

- (BOOL)srg_isTrackedAutomatically
{
    return [self.file isEqualToString:@"Root"] || [self.file containsString:@"com.mono0926.LicensePlist"];
}

- (NSString *)srg_pageViewTitle
{
    if ([self.file isEqualToString:@"Root"]) {
        return AnalyticsPageTitleSettings;
    }
    else if ([self.file isEqualToString:@"com.mono0926.LicensePlist"]) {
        return AnalyticsPageTitleLicenses;
    }
    else {
        return AnalyticsPageTitleLicense;
    }
}

- (NSArray<NSString *> *)srg_pageViewLevels
{
    return @[ AnalyticsPageLevelPlay, AnalyticsPageLevelApplication ];
}

#pragma mark Actions

- (void)close:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark Notifications

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
