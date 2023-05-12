//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "Favorites.h"

#import "PlaySRG-Swift.h"

#if TARGET_OS_IOS
#import "PlaySRG-Swift.h"
#import "PushService+Private.h"
#endif

@import libextobjc;
@import SRGUserData;

NSString * const PlayPreferencesDomain = @"play";

static NSString * const PlayFavoritesPath = @"favorites";
static NSString * const PlayDatePath = @"date";
static NSString * const PlayNotificationsPath = @"notifications";
static NSString * const PlayNewOnDemandPath = @"newod";

#pragma mark Private

BOOL FavoritesContainsShowURN(NSString *URN)
{
    NSString *path = [PlayFavoritesPath stringByAppendingPathComponent:URN];
    return [SRGUserData.currentUserData.preferences hasObjectAtPath:path inDomain:PlayPreferencesDomain];
}

BOOL FavoritesIsSubscribedToShowURN(NSString * _Nonnull URN)
{
    if (! FavoritesContainsShowURN(URN)) {
        return NO;
    }
    
    NSString *path = [[[PlayFavoritesPath stringByAppendingPathComponent:URN] stringByAppendingPathComponent:PlayNotificationsPath] stringByAppendingPathComponent:PlayNewOnDemandPath];
    return [SRGUserData.currentUserData.preferences numberAtPath:path inDomain:PlayPreferencesDomain].boolValue;
}

#pragma mark Favorite entries

BOOL FavoritesContainsShow(SRGShow *show)
{
    return FavoritesContainsShowURN(show.URN);
}

void FavoritesAddShow(SRGShow *show)
{
    if (! FavoritesContainsShowURN(show.URN)) {
        NSString *path = [[PlayFavoritesPath stringByAppendingPathComponent:show.URN] stringByAppendingPathComponent:PlayDatePath];
        [SRGUserData.currentUserData.preferences setNumber:@(round(NSDate.date.timeIntervalSince1970 * 1000.)) atPath:path inDomain:PlayPreferencesDomain];
        [UserInteractionEvent addToFavorites:@[show]];
    }
}

void FavoritesRemoveShows(NSArray<SRGShow *> *shows)
{
    NSArray<NSString *> *URNs = nil;
    if (shows) {
        NSString *keyPath = [NSString stringWithFormat:@"@distinctUnionOfObjects.%@", @keypath(SRGShow.new, URN)];
        URNs = [shows valueForKeyPath:keyPath];
    }
    else {
        URNs = FavoritesShowURNs().array;
    }
    
    NSMutableArray<NSString *> *paths = NSMutableArray.array;
    for (NSString *URN in URNs) {
        [paths addObject:[PlayFavoritesPath stringByAppendingPathComponent:URN]];
    }
    [SRGUserData.currentUserData.preferences removeObjectsAtPaths:paths.copy inDomain:PlayPreferencesDomain];
    [UserInteractionEvent removeFromFavorites:shows];
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

NSOrderedSet<NSString *> *FavoritesShowURNs(void)
{
    NSArray<NSString *> *URNs = [[SRGUserData.currentUserData.preferences dictionaryAtPath:PlayFavoritesPath inDomain:PlayPreferencesDomain].allKeys sortedArrayUsingSelector:@selector(compare:)];
    return URNs ? [NSOrderedSet orderedSetWithArray:URNs] : [NSOrderedSet orderedSet];
}

#pragma mark Notification subscriptions

BOOL FavoritesIsSubscribedToShow(SRGShow *show)
{
    return FavoritesIsSubscribedToShowURN(show.URN);
}

#if TARGET_OS_IOS

BOOL FavoritesToggleSubscriptionForShow(SRGShow *show)
{
    if (! FavoritesContainsShow(show)) {
        return NO;
    }
    
    if (! [PushService.sharedService toggleSubscriptionForShow:show]) {
        return NO;
    }
    
    BOOL subscribed = [PushService.sharedService isSubscribedToShowURN:show.URN];
    NSString *path = [[[PlayFavoritesPath stringByAppendingPathComponent:show.URN] stringByAppendingPathComponent:PlayNotificationsPath] stringByAppendingPathComponent:PlayNewOnDemandPath];
    [SRGUserData.currentUserData.preferences setNumber:@(subscribed) atPath:path inDomain:PlayPreferencesDomain];
    
    return YES;
}

#pragma mark Push service synchronization

void FavoritesUpdatePushService(void)
{
    if (! PushService.sharedService) {
        return;
    }
    
    NSMutableSet<NSString *> *subscribedURNs = [NSMutableSet set];
    for (NSString *URN in FavoritesShowURNs()) {
        if (FavoritesIsSubscribedToShowURN(URN)) {
            [subscribedURNs addObject:URN];
        }
    }
    NSSet<NSString *> *subscribedPushServiceURNs = PushService.sharedService.subscribedShowURNs;
    
    if (! [subscribedURNs isEqualToSet:subscribedPushServiceURNs]) {
        NSSet<NSString *> *toSubscribeURNs = [subscribedURNs setByRemovingObjectsIn:subscribedPushServiceURNs];
        [PushService.sharedService subscribeToShowURNs:toSubscribeURNs];
        
        NSSet<NSString *> *toUnsubscribeURNs = [subscribedPushServiceURNs setByRemovingObjectsIn:subscribedURNs];
        [PushService.sharedService unsubscribeFromShowURNs:toUnsubscribeURNs];
    }
    
    NSCAssert([subscribedURNs isEqualToSet:PushService.sharedService.subscribedShowURNs], @"Subscribed favorite shows have to be equal to Push Service subscribed shows");
}

#endif
