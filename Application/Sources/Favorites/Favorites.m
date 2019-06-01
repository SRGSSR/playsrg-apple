//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "Favorites.h"

#import "DeprecatedFavorite+Private.h"
#import "NSSet+PlaySRG.h"
#import "PlayApplication.h"
#import "PushService+Private.h"

#import <libextobjc/libextobjc.h>
#import <SRGUserData/SRGUserData.h>

NSString * const PlayPreferencesDomain = @"play";

static NSString * const PlayFavoritesPath = @"favorites";
static NSString * const PlayDatePath = @"date";
static NSString * const PlayNotificationsPath = @"notifications";
static NSString * const PlayNewOnDemandPath = @"newod";

static NSString * const SubscriptionsToFavoritesMigrationDoneKey = @"SubscriptionsToFavoritesMigrationDone";

#pragma mark Private

BOOL FavoritesContainsShowURN(NSString *URN)
{
    NSString *path = [PlayFavoritesPath stringByAppendingPathComponent:URN];
    return [SRGUserData.currentUserData.preferences hasObjectAtPath:path inDomain:PlayPreferencesDomain];
}

void FavoritesAddShowURNWithDate(NSString *URN, NSDate *date)
{
    if (! FavoritesContainsShowURN(URN)) {
        NSString *path = [[PlayFavoritesPath stringByAppendingPathComponent:URN] stringByAppendingPathComponent:PlayDatePath];
        [SRGUserData.currentUserData.preferences setNumber:@(round(date.timeIntervalSince1970 * 1000.)) atPath:path inDomain:PlayPreferencesDomain];
    }
}

BOOL FavoritesIsSubscribedToShowURN(NSString * _Nonnull URN)
{
    if (! FavoritesContainsShowURN(URN)) {
        return NO;
    }
    
    if (! PushService.sharedService.enabled) {
        return NO;
    }
    
    NSString *path = [[[PlayFavoritesPath stringByAppendingPathComponent:URN] stringByAppendingPathComponent:PlayNotificationsPath] stringByAppendingPathComponent:PlayNewOnDemandPath];
    return [SRGUserData.currentUserData.preferences numberAtPath:path inDomain:PlayPreferencesDomain].boolValue;
}

// Force subscription, even if Push Notifications are disabled.
void FavoritesSubscribeToShowURN(NSString *URN)
{
    if (FavoritesContainsShowURN(URN) && ! FavoritesIsSubscribedToShowURN(URN)) {
        NSString *path = [[[PlayFavoritesPath stringByAppendingPathComponent:URN] stringByAppendingPathComponent:PlayNotificationsPath] stringByAppendingPathComponent:PlayNewOnDemandPath];
        [SRGUserData.currentUserData.preferences setNumber:@YES atPath:path inDomain:PlayPreferencesDomain];
    }
}

#pragma mark Push service synchronization

void FavoritesUpdatePushService(void)
{
    if ([PlayApplicationRunOnceObjectForKey(SubscriptionsToFavoritesMigrationDoneKey) boolValue]) {
        NSMutableSet<NSString *> *subscribedURNs = [NSMutableSet set];
        for (NSString *URN in FavoritesShowURNs()) {
            if (FavoritesIsSubscribedToShowURN(URN)) {
                [subscribedURNs addObject:URN];
            }
        }
        NSSet<NSString *> *subscribedPushServiceURNs = PushService.sharedService.subscribedShowURNs;
        
        if (! [subscribedURNs isEqualToSet:subscribedPushServiceURNs]) {
            NSSet<NSString *> *toSubscribeURNs = [subscribedURNs play_setByRemovingObjectsInSet:subscribedPushServiceURNs];
            [PushService.sharedService subscribeToShowURNs:toSubscribeURNs];
            
            NSSet<NSString *> *toUnsubscribeURNs = [subscribedPushServiceURNs play_setByRemovingObjectsInSet:subscribedURNs];
            [PushService.sharedService unsubscribeFromShowURNs:toUnsubscribeURNs];
        }
        
        NSCAssert([subscribedURNs isEqualToSet:PushService.sharedService.subscribedShowURNs], @"Subscribed favorite shows have to be equal to Push Service subscribed shows");
    }
}

void FavoritesSetup(void)
{
    FavoritesUpdatePushService();
    
    [NSNotificationCenter.defaultCenter addObserverForName:SRGPreferencesDidChangeNotification object:SRGUserData.currentUserData.preferences queue:nil usingBlock:^(NSNotification * _Nonnull notification) {
        NSSet<NSString *> *domains = notification.userInfo[SRGPreferencesDomainsKey];
        if ([domains containsObject:PlayPreferencesDomain]) {
            FavoritesUpdatePushService();
        }
    }];
}

#pragma mark Favorite entries

BOOL FavoritesContainsShow(SRGShow *show)
{
    return FavoritesContainsShowURN(show.URN);
}

void FavoritesAddShow(SRGShow *show)
{
    FavoritesAddShowURNWithDate(show.URN, NSDate.date);
}

void FavoritesRemoveShows(NSArray<SRGShow *> *shows)
{
    NSArray<NSString *> *URNs = nil;
    if (shows) {
        NSString *keyPath = [NSString stringWithFormat:@"@distinctUnionOfObjects.%@", @keypath(SRGShow.new, URN)];
        URNs = [shows valueForKeyPath:keyPath];
    }
    else {
        URNs = FavoritesShowURNs().allObjects;
    }
    
    NSMutableArray<NSString *> *paths = NSMutableArray.array;
    for (NSString *URN in URNs) {
        [paths addObject:[PlayFavoritesPath stringByAppendingPathComponent:URN]];
    }
    [SRGUserData.currentUserData.preferences removeObjectsAtPaths:paths.copy inDomain:PlayPreferencesDomain];
}

void FavoritesToggleShow(SRGShow *show)
{
    if (FavoritesContainsShow(show)) {
        FavoritesRemoveShows(@[show]);
    }
    else {
        FavoritesAddShow(show);
    }
}

NSSet<NSString *> *FavoritesShowURNs(void)
{
    NSArray<NSString *> *URNs = [SRGUserData.currentUserData.preferences dictionaryAtPath:PlayFavoritesPath inDomain:PlayPreferencesDomain].allKeys;
    return URNs ? [NSSet setWithArray:URNs] : [NSSet set];
}

#pragma mark Notification subscriptions

BOOL FavoritesToggleSubscriptionForShow(SRGShow *show, UIView *view)
{
    if (! FavoritesContainsShow(show)) {
        return NO;
    }
    
    BOOL toggled = NO;
    if (view) {
        toggled = [PushService.sharedService toggleSubscriptionForShow:show inView:view];
    }
    else {
        toggled = [PushService.sharedService toggleSubscriptionForShow:show];
    }
    
    if (! toggled) {
        return NO;
    }
    
    BOOL subscribed = [PushService.sharedService isSubscribedToShowURN:show.URN];
    NSString *path = [[[PlayFavoritesPath stringByAppendingPathComponent:show.URN] stringByAppendingPathComponent:PlayNotificationsPath] stringByAppendingPathComponent:PlayNewOnDemandPath];
    [SRGUserData.currentUserData.preferences setNumber:@(subscribed) atPath:path inDomain:PlayPreferencesDomain];
    
    return YES;
}

BOOL FavoritesIsSubscribedToShow(SRGShow *show)
{
    return FavoritesIsSubscribedToShowURN(show.URN);
}

#pragma mark Migration

void FavoritesMigrate(void)
{    
    NSArray<DeprecatedFavorite *> *favorites = [DeprecatedFavorite showFavorites];
    if (favorites.count != 0) {
        for (DeprecatedFavorite *favorite in favorites) {
            if (favorite.showURN && ! FavoritesContainsShowURN(favorite.showURN)) {
                FavoritesAddShowURNWithDate(favorite.showURN, favorite.date ?: NSDate.date);
            }
        }
        [DeprecatedFavorite finishMigrationForFavorites:favorites];
    }
    
    // Processes run once in the lifetime of the application
    PlayApplicationRunOnce(^(void (^completionHandler)(BOOL success)) {
        NSSet<NSString *> *subscribedShowURNs = PushService.sharedService.subscribedShowURNs;
        
        for (NSString *URN in subscribedShowURNs) {
            if (! FavoritesContainsShowURN(URN)) {
                FavoritesAddShowURNWithDate(URN, NSDate.date);
            }
            FavoritesSubscribeToShowURN(URN);
        }
        completionHandler(YES);
    }, SubscriptionsToFavoritesMigrationDoneKey, nil);
}
