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

BOOL MyListContainsShow(SRGShow *show)
{
    return [[SRGUserData.currentUserData.preferences dictionaryAtPath:MyListPreferencePath inDomain:PlayPreferenceDomain].allKeys containsObject:show.URN];
}

void MyListAddShow(SRGShow *show)
{
    if (! MyListContainsShow(show)) {
        NSDictionary *myListEntry = @{ @"date" : @(NSDate.date.timeIntervalSince1970),
                                       @"newodNotification" : @(NO) };
        [SRGUserData.currentUserData.preferences setDictionary:myListEntry atPath:[NSString stringWithFormat:@"%@/%@", MyListPreferencePath, show.URN] inDomain:PlayPreferenceDomain];
    }
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

NSArray<NSString *> * MyListShowURNs()
{
    return [SRGUserData.currentUserData.preferences dictionaryAtPath:MyListPreferencePath inDomain:PlayPreferenceDomain].allKeys;
}

void MyListMigrate(void)
{
    NSArray<Favorite *> *favorites = [Favorite showFavorites];
    if (favorites.count) {
        NSMutableArray<NSString *> *URNs = [SRGUserData.currentUserData.preferences arrayAtPath:@"myList" inDomain:PlayPreferenceDomain].mutableCopy ?: NSMutableArray.new;
        for (Favorite *favorite in favorites) {
            if (favorite.showURN && ! [URNs containsObject:favorite.showURN]) {
                [URNs insertObject:favorite.showURN atIndex:0];
            }
        }
        [SRGUserData.currentUserData.preferences setArray:URNs.copy atPath:@"myList" inDomain:PlayPreferenceDomain];
        [Favorite finishMigrationForFavorites:favorites];
    }
    
    // Processes run once in the lifetime of the application
    PlayApplicationRunOnce(^(void (^completionHandler)(BOOL success)) {
        NSArray<NSString *> *subscribedShowURNs = PushService.sharedService.subscribedShowURNs;
        
        for (NSString *URN in subscribedShowURNs) {
            NSInteger index = [[SRGUserData.currentUserData.preferences arrayAtPath:@"myList" inDomain:PlayPreferenceDomain] ?: @[] indexOfObject:URN];
            if (index == NSNotFound) {
                NSMutableArray<NSString *> *URNs = [SRGUserData.currentUserData.preferences arrayAtPath:@"myList" inDomain:PlayPreferenceDomain].mutableCopy ?: NSMutableArray.new;
                [URNs insertObject:URN atIndex:0];
                [SRGUserData.currentUserData.preferences setArray:URNs.copy atPath:@"myList" inDomain:PlayPreferenceDomain];
            }
        }
        completionHandler(subscribedShowURNs != nil);
    }, @"SubscriptionsToMyListMigrationDone", nil);
}
