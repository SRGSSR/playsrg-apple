//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "MyList.h"

#import "Favorite+Private.h"
#import "PlayApplication.h"
#import "PushService.h"

#import <libextobjc/libextobjc.h>
#import <SRGUserData/SRGUserData.h>

static NSString * const PlayPreferenceDomain = @"play";
static NSString * const MyListPreferencePath = @"myList";

#pragma mark Media metadata functions

BOOL MyListContainsShowURN(NSString *URN)
{
    return [[SRGUserData.currentUserData.preferences dictionaryAtPath:MyListPreferencePath inDomain:PlayPreferenceDomain].allKeys containsObject:URN];
}

BOOL MyListContainsShow(SRGShow *show)
{
    return MyListContainsShowURN(show.URN);
}

void MyListAddShowURNWithDate(NSString *URN, NSDate *date)
{
    if (! MyListContainsShowURN(URN)) {
        NSDictionary *myListEntry = @{ @"date" : @(date.timeIntervalSince1970),
                                       @"notifications" : @{} };
        [SRGUserData.currentUserData.preferences setDictionary:myListEntry atPath:[NSString stringWithFormat:@"%@/%@", MyListPreferencePath, URN] inDomain:PlayPreferenceDomain];
    }
}

void MyListSubscribedToShowURN(NSString *URN)
{
    if (MyListContainsShowURN(URN)) {
        NSMutableDictionary *notifications = [SRGUserData.currentUserData.preferences dictionaryAtPath:[NSString stringWithFormat:@"%@/%@/%@", MyListPreferencePath, URN, @"notifications"] inDomain:PlayPreferenceDomain].mutableCopy;
        notifications[@"newod"] = @(YES);
        [SRGUserData.currentUserData.preferences setDictionary:notifications.copy atPath:[NSString stringWithFormat:@"%@/%@/%@", MyListPreferencePath, URN, @"notifications"] inDomain:PlayPreferenceDomain];
    }
}

void MyListUnsubscribedFromShowURN(NSString *URN)
{
    if (MyListContainsShowURN(URN)) {
        NSMutableDictionary *notifications = [SRGUserData.currentUserData.preferences dictionaryAtPath:[NSString stringWithFormat:@"%@/%@/%@", MyListPreferencePath, URN, @"notifications"] inDomain:PlayPreferenceDomain].mutableCopy;
        notifications[@"newod"] = @(NO);
        [SRGUserData.currentUserData.preferences setDictionary:notifications.copy atPath:[NSString stringWithFormat:@"%@/%@/%@", MyListPreferencePath, URN, @"notifications"] inDomain:PlayPreferenceDomain];
    }
}

void MyListAddShow(SRGShow *show)
{
    MyListAddShowURNWithDate(show.URN, NSDate.date);
}

void MyListRemoveShows(NSArray<SRGShow *> *shows)
{
    if (shows) {
        for (SRGShow *show in shows) {
            [SRGUserData.currentUserData.preferences removeObjectAtPath:[NSString stringWithFormat:@"%@/%@", MyListPreferencePath, show.URN] inDomain:PlayPreferenceDomain];
        }
        NSString *keyPath = [NSString stringWithFormat:@"@distinctUnionOfObjects.%@", @keypath(SRGShow.new, URN)];
        [PushService.sharedService silenceUnsubscribtionFromShowURNs:[shows valueForKeyPath:keyPath]];
    }
    else {
        [SRGUserData.currentUserData.preferences setDictionary:@{} atPath:MyListPreferencePath inDomain:PlayPreferenceDomain];
        
        [PushService.sharedService silenceUnsubscribtionFromShowURNs:PushService.sharedService.subscribedShowURNs];
        
    }
}

BOOL MyListToggleShow(SRGShow *show)
{
    BOOL contained = MyListContainsShow(show);
    if (contained) {
        MyListRemoveShows(@[show]);
        return NO;
    }
    else {
        MyListAddShow(show);
        return YES;
    }
}

NSSet<NSString *> * MyListShowURNs()
{
    return [NSSet setWithArray:[SRGUserData.currentUserData.preferences dictionaryAtPath:MyListPreferencePath inDomain:PlayPreferenceDomain].allKeys];
}

void MyListMigrate(void)
{
    NSArray<Favorite *> *favorites = [Favorite showFavorites];
    if (favorites.count) {
        for (Favorite *favorite in favorites) {
            if (favorite.showURN && ! MyListContainsShowURN(favorite.showURN)) {
                MyListAddShowURNWithDate(favorite.showURN, favorite.date ?: NSDate.date);
            }
        }
        [Favorite finishMigrationForFavorites:favorites];
    }
    
    // Processes run once in the lifetime of the application
    PlayApplicationRunOnce(^(void (^completionHandler)(BOOL success)) {
        NSSet<NSString *> *subscribedShowURNs = PushService.sharedService.subscribedShowURNs;
        
        for (NSString *URN in subscribedShowURNs) {
            if (! MyListContainsShowURN(URN)) {
                MyListAddShowURNWithDate(URN, NSDate.date);
            }
            MyListSubscribedToShowURN(URN);
        }
        completionHandler(subscribedShowURNs != nil);
    }, @"SubscriptionsToMyListMigrationDone", nil);
}
