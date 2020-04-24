//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "HomeSectionInfo.h"

#import "ApplicationConfiguration.h"
#import "ApplicationSettings.h"
#import "Favorites.h"
#import "HomeMediaListTableViewCell.h"
#import "HomeShowListTableViewCell.h"
#import "HomeShowsAccessTableViewCell.h"
#import "HomeShowVerticalListTableViewCell.h"

#import <libextobjc/libextobjc.h>
#import <SRGDataProvider/SRGDataProvider.h>

@interface HomeSectionInfo ()

@property (nonatomic) HomeSection homeSection;
@property (nonatomic) id object;
@property (nonatomic) TopicSection topicSection;

@property (nonatomic) NSArray *items;

// Used for regional radio overriding
@property (nonatomic) NSMutableArray<SRGMedia *> *pendingMedias;
@property (nonatomic, copy) SRGMediaListCompletionBlock pendingCompletionBlock;

@end

@implementation HomeSectionInfo

#pragma Object lifecycle

- (instancetype)initWithHomeSection:(HomeSection)homeSection topicSection:(TopicSection)topicSection object:(id)object
{
    if (self = [super init]) {
        self.homeSection = homeSection;
        self.topicSection = topicSection;
        self.object = object;
    }
    return self;
}

- (instancetype)initWithHomeSection:(HomeSection)homeSection object:(id)object
{
    return [self initWithHomeSection:homeSection topicSection:TopicSectionUnknown object:object];
}

- (instancetype)initWithHomeSection:(HomeSection)homeSection
{
    return [self initWithHomeSection:homeSection topicSection:TopicSectionUnknown object:nil];
}

- (instancetype)init
{
    [self doesNotRecognizeSelector:_cmd];
    return [self initWithHomeSection:HomeSectionUnknown object:nil];
}

#pragma mark Getters and setters

- (Class)cellClass
{
    if (self.homeSection == HomeSectionRadioAllShows) {
        return HomeShowVerticalListTableViewCell.class;
    }
    else if (self.homeSection == HomeSectionTVShowsAccess || self.homeSection == HomeSectionRadioShowsAccess) {
        return HomeShowsAccessTableViewCell.class;
    }
    else if (self.homeSection == HomeSectionTVFavoriteShows || self.homeSection == HomeSectionRadioFavoriteShows) {
        return HomeShowListTableViewCell.class;
    }
    else {
        return HomeMediaListTableViewCell.class;
    }
}

- (BOOL)canOpenList
{
    return self.homeSection != HomeSectionTVLive && self.homeSection != HomeSectionRadioLive && self.homeSection != HomeSectionRadioLiveSatellite
        && self.homeSection != HomeSectionRadioAllShows
        && self.homeSection != HomeSectionTVShowsAccess && self.homeSection != HomeSectionRadioShowsAccess
        && self.homeSection != HomeSectionTVFavoriteShows && self.homeSection != HomeSectionRadioFavoriteShows
        && ! [self isPlaceholder];
}

- (BOOL)isHidden
{
    // Favorites: Can be hidden when no item is available
    if (self.homeSection == HomeSectionTVFavoriteShows || self.homeSection == HomeSectionRadioFavoriteShows) {
        return self.items.count == 0;
    }
    // All other rows: Even when empty, a placeholder is displayed instead
    else {
        return NO;
    }
}

- (BOOL)isPlaceholder
{
    return (self.homeSection == HomeSectionTVTopics || self.homeSection == HomeSectionTVEvents) && ! self.object;
}

- (NSString *)identifier
{
    return [self.object isKindOfClass:NSString.class] ? self.object : nil;
}

- (SRGModule *)module
{
    return [self.object isKindOfClass:SRGModule.class] ? self.object : nil;
}

- (SRGBaseTopic *)topic
{
    return [self.object isKindOfClass:SRGBaseTopic.class] ? self.object : nil;
}

#pragma mark Data

- (void)refreshRadioLivestreamsForVendor:(SRGVendor)vendor withRequestQueue:(SRGRequestQueue *)requestQueue completionBlock:(SRGMediaListCompletionBlock)completionBlock
{
    SRGBaseRequest *request = [SRGDataProvider.currentDataProvider radioLivestreamsForVendor:vendor contentProviders:SRGContentProvidersDefault withCompletionBlock:^(NSArray<SRGMedia *> * _Nullable originalMedias, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
        [requestQueue reportError:error];
        
        // For radio livestreams, override standard channel media with latest regional radio selection if available
        if (self.homeSection == HomeSectionRadioLive) {
            NSMutableArray<SRGMedia *> *medias = originalMedias.mutableCopy;
            
            self.pendingCompletionBlock = completionBlock;
            self.pendingMedias = NSMutableArray.array;
            
            void (^checkCompletion)(void) = ^{
                if (self.pendingMedias.count == 0) {
                    self.pendingCompletionBlock(medias.copy, HTTPResponse, error);
                    self.pendingCompletionBlock = nil;
                    self.pendingMedias = nil;
                }
            };
            
            for (SRGMedia *originalMedia in originalMedias) {
                NSString *selectedLivestreamURN = ApplicationSettingSelectedLivestreamURNForChannelUid(originalMedia.channel.uid);
                
                // If a regional stream has been selected by the user, replace the main channel media with it
                if (selectedLivestreamURN && ! [originalMedia.URN isEqual:selectedLivestreamURN]) {
                    [self.pendingMedias addObject:originalMedia];
                    
                    SRGRequest *request = [SRGDataProvider.currentDataProvider radioLivestreamsForVendor:vendor channelUid:originalMedia.channel.uid withCompletionBlock:^(NSArray<SRGMedia *> * _Nullable channelMedias, NSHTTPURLResponse * _Nullable channelMediasHTTPResponse, NSError * _Nullable error) {
                        [requestQueue reportError:error];
                        
                        SRGMedia *selectedMedia = ApplicationSettingSelectedLivestreamMediaForChannelUid(originalMedia.channel.uid, channelMedias);
                        if (selectedMedia) {
                            NSInteger index = [medias indexOfObject:originalMedia];
                            NSAssert(index != NSNotFound, @"Media must be found in array by construction");
                            [medias replaceObjectAtIndex:index withObject:selectedMedia];
                        }
                        
                        [self.pendingMedias removeObject:originalMedia];
                        checkCompletion();
                    }];
                    [requestQueue addRequest:request resume:YES];
                }
            }
            checkCompletion();
        }
        // For other livestream types, do nothing
        else {
            completionBlock(originalMedias, HTTPResponse, error);
        }
    }];
    [requestQueue addRequest:request resume:YES];
}

- (void)refreshFavoriteShowsForVendor:(SRGVendor)vendor transmission:(SRGTransmission)transmission channelUid:(NSString *)channelUid withRequestQueue:(SRGRequestQueue *)requestQueue completionBlock:(SRGShowListCompletionBlock)completionBlock
{
    NSArray<NSString *> *showURNs = FavoritesShowURNs().allObjects;
    NSMutableArray<SRGShow *> *allShows = [NSMutableArray array];
    
    // We must retrieve all shows in all cases since there is no way to know which ones match the `transmission` and `channelUid` parameters
    __block SRGFirstPageRequest *firstRequest = nil;
    firstRequest = [[SRGDataProvider.currentDataProvider showsWithURNs:showURNs completionBlock:^(NSArray<SRGShow *> * _Nullable shows, SRGPage * _Nonnull page, SRGPage * _Nullable nextPage, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
        if (error) {
            [requestQueue reportError:error];
            return;
        }
        
        [allShows addObjectsFromArray:shows];
        
        if (nextPage) {
            SRGPageRequest *nextRequest = [firstRequest requestWithPage:nextPage];
            [requestQueue addRequest:nextRequest resume:YES];
        }
        else {
            NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(SRGShow * _Nullable show, NSDictionary<NSString *,id> * _Nullable bindings) {
                return transmission == show.transmission && (! channelUid || [channelUid isEqualToString:show.primaryChannelUid]);
            }];
            NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@keypath(SRGShow.new, title) ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)];
            completionBlock([[allShows filteredArrayUsingPredicate:predicate] sortedArrayUsingDescriptors:@[sortDescriptor]], HTTPResponse, error);
            firstRequest = nil;
        }
    }] requestWithPageSize:50 /* Use largest page size */];
    [requestQueue addRequest:firstRequest resume:YES];
}

- (void)refreshWithRequestQueue:(SRGRequestQueue *)requestQueue page:(SRGPage *)page completionBlock:(SRGPaginatedItemListCompletionBlock)completionBlock
{
    ApplicationConfiguration *applicationConfiguration = ApplicationConfiguration.sharedApplicationConfiguration;
    
    NSUInteger pageSize = applicationConfiguration.pageSize;
    SRGVendor vendor = applicationConfiguration.vendor;
    
    SRGPaginatedItemListCompletionBlock paginatedItemListCompletionBlock = ^(NSArray * _Nullable items, SRGPage *page, SRGPage * _Nullable nextPage, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
        // Keep previous items in case of an error
        if (items) {
            self.items = items;
        }
        completionBlock(items, page, nextPage, HTTPResponse, error);
    };
    
    switch (self.homeSection) {
        case HomeSectionTVTrending: {
            SRGBaseRequest *request = [SRGDataProvider.currentDataProvider tvTrendingMediasForVendor:vendor withLimit:@(pageSize) editorialLimit:applicationConfiguration.tvTrendingEditorialLimit episodesOnly:applicationConfiguration.tvTrendingEpisodesOnly completionBlock:^(NSArray<SRGMedia *> * _Nullable medias, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
                [requestQueue reportError:error];
                paginatedItemListCompletionBlock(medias, [SRGPage new] /* The request does not support pagination, but we need to return a page */, nil, HTTPResponse, error);
            }];
            [requestQueue addRequest:request resume:YES];
            break;
        }
            
        case HomeSectionTVFavoriteShows: {
            [self refreshFavoriteShowsForVendor:vendor transmission:SRGTransmissionTV channelUid:self.identifier withRequestQueue:requestQueue completionBlock:^(NSArray<SRGShow *> * _Nullable shows, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
                // Error reporting is done by the refresh method directly, do not report twice here
                paginatedItemListCompletionBlock(shows, [SRGPage new] /* The request does not support pagination, but we need to return a page */, nil, HTTPResponse, error);
            }];
            break;
        }
            
        case HomeSectionTVLive: {
            SRGBaseRequest *request = [SRGDataProvider.currentDataProvider tvLivestreamsForVendor:vendor withCompletionBlock:^(NSArray<SRGMedia *> * _Nullable medias, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
                [requestQueue reportError:error];
                paginatedItemListCompletionBlock(medias, [SRGPage new] /* The request does not support pagination, but we need to return a page */, nil, HTTPResponse, error);
            }];
            [requestQueue addRequest:request resume:YES];
            break;
        }
            
        case HomeSectionTVEvents: {
            SRGModule *module = self.module;
            if (module) {
                SRGBaseRequest *request = [[[SRGDataProvider.currentDataProvider latestMediasForModuleWithURN:module.URN completionBlock:^(NSArray<SRGMedia *> * _Nullable medias, SRGPage * _Nonnull page, SRGPage * _Nullable nextPage, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
                    [requestQueue reportError:error];
                    paginatedItemListCompletionBlock(medias, page, nextPage, HTTPResponse, error);
                }] requestWithPageSize:pageSize] requestWithPage:page];
                [requestQueue addRequest:request resume:YES];
            }
            break;
        }
            
        case HomeSectionTVTopics: {
            SRGBaseTopic *topic = self.topic;
            if (topic) {
                if (self.topicSection == TopicSectionMostPopular) {
                    SRGBaseRequest *request = [[[SRGDataProvider.currentDataProvider mostPopularMediasForTopicWithURN:topic.URN completionBlock:^(NSArray<SRGMedia *> * _Nullable medias, SRGPage * _Nonnull page, SRGPage * _Nullable nextPage, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
                        [requestQueue reportError:error];
                        paginatedItemListCompletionBlock(medias, page, nextPage, HTTPResponse, error);
                    }] requestWithPageSize:pageSize] requestWithPage:page];
                    [requestQueue addRequest:request resume:YES];
                }
                else {
                    SRGBaseRequest *request = [[[SRGDataProvider.currentDataProvider latestMediasForTopicWithURN:topic.URN completionBlock:^(NSArray<SRGMedia *> * _Nullable medias, SRGPage * _Nonnull page, SRGPage * _Nullable nextPage, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
                        [requestQueue reportError:error];
                        paginatedItemListCompletionBlock(medias, page, nextPage, HTTPResponse, error);
                    }] requestWithPageSize:pageSize] requestWithPage:page];
                    [requestQueue addRequest:request resume:YES];
                }
            }
            break;
        }
            
        case HomeSectionTVLatest: {
            SRGBaseRequest *request = [[[SRGDataProvider.currentDataProvider tvLatestMediasForVendor:vendor withCompletionBlock:^(NSArray<SRGMedia *> * _Nullable medias, SRGPage * _Nonnull page, SRGPage * _Nullable nextPage, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
                [requestQueue reportError:error];
                paginatedItemListCompletionBlock(medias, page, nextPage, HTTPResponse, error);
            }] requestWithPageSize:pageSize] requestWithPage:page];
            [requestQueue addRequest:request resume:YES];
            break;
        }
            
        case HomeSectionTVMostPopular: {
            SRGBaseRequest *request = [[[SRGDataProvider.currentDataProvider tvMostPopularMediasForVendor:vendor withCompletionBlock:^(NSArray<SRGMedia *> * _Nullable medias, SRGPage * _Nonnull page, SRGPage * _Nullable nextPage, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
                [requestQueue reportError:error];
                paginatedItemListCompletionBlock(medias, page, nextPage, HTTPResponse, error);
            }] requestWithPageSize:pageSize] requestWithPage:page];
            [requestQueue addRequest:request resume:YES];
            break;
        }
            
        case HomeSectionTVSoonExpiring: {
            SRGBaseRequest *request = [[[SRGDataProvider.currentDataProvider tvSoonExpiringMediasForVendor:vendor withCompletionBlock:^(NSArray<SRGMedia *> * _Nullable medias, SRGPage * _Nonnull page, SRGPage * _Nullable nextPage, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
                [requestQueue reportError:error];
                paginatedItemListCompletionBlock(medias, page, nextPage, HTTPResponse, error);
            }] requestWithPageSize:pageSize] requestWithPage:page];
            [requestQueue addRequest:request resume:YES];
            break;
        }
            
        case HomeSectionTVLiveCenter: {
            SRGBaseRequest *request = [[[SRGDataProvider.currentDataProvider liveCenterVideosForVendor:vendor withCompletionBlock:^(NSArray<SRGMedia *> * _Nullable medias, SRGPage * _Nonnull page, SRGPage * _Nullable nextPage, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
                [requestQueue reportError:error];
                paginatedItemListCompletionBlock(medias, page, nextPage, HTTPResponse, error);
            }] requestWithPageSize:pageSize] requestWithPage:page];
            [requestQueue addRequest:request resume:YES];
            break;
        }
            
        case HomeSectionTVScheduledLivestreams: {
            SRGBaseRequest *request = [[[SRGDataProvider.currentDataProvider tvScheduledLivestreamsForVendor:vendor withCompletionBlock:^(NSArray<SRGMedia *> * _Nullable medias, SRGPage * _Nonnull page, SRGPage * _Nullable nextPage, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
                [requestQueue reportError:error];
                paginatedItemListCompletionBlock(medias, page, nextPage, HTTPResponse, error);
            }] requestWithPageSize:pageSize] requestWithPage:page];
            [requestQueue addRequest:request resume:YES];
            break;
        }
            
        case HomeSectionRadioLive: {
            if (self.identifier) {
                SRGRequest *request = [SRGDataProvider.currentDataProvider radioLivestreamsForVendor:vendor channelUid:self.identifier withCompletionBlock:^(NSArray<SRGMedia *> * _Nullable medias, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
                    [requestQueue reportError:error];
                    paginatedItemListCompletionBlock(medias, [SRGPage new] /* The request does not support pagination, but we need to return a page */, nil, HTTPResponse, error);
                }];
                [requestQueue addRequest:request resume:YES];
            }
            else {
                [self refreshRadioLivestreamsForVendor:vendor withRequestQueue:requestQueue completionBlock:^(NSArray<SRGMedia *> * _Nullable medias, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
                    // Error reporting is done by the refresh method directly, do not report twice here
                    paginatedItemListCompletionBlock(medias, [SRGPage new] /* The request does not support pagination, but we need to return a page */, nil, HTTPResponse, error);
                }];
            }
            break;
        }
            
        case HomeSectionRadioLiveSatellite: {
            SRGBaseRequest *request = [SRGDataProvider.currentDataProvider radioLivestreamsForVendor:vendor contentProviders:SRGContentProvidersSwissSatelliteRadio withCompletionBlock:^(NSArray<SRGMedia *> * _Nullable medias, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
                [requestQueue reportError:error];
                paginatedItemListCompletionBlock(medias, [SRGPage new] /* The request does not support pagination, but we need to return a page */, nil, HTTPResponse, error);
            }];
            [requestQueue addRequest:request resume:YES];
            break;
        }
            
        case HomeSectionRadioFavoriteShows: {
            [self refreshFavoriteShowsForVendor:vendor transmission:SRGTransmissionRadio channelUid:self.identifier withRequestQueue:requestQueue completionBlock:^(NSArray<SRGShow *> * _Nullable shows, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
                // Error reporting is done by the refresh method directly, do not report twice here
                paginatedItemListCompletionBlock(shows, [SRGPage new] /* The request does not support pagination, but we need to return a page */, nil, HTTPResponse, error);
            }];
            break;
        }
            
        case HomeSectionRadioLatestEpisodes: {
            NSString *identifier = self.identifier;
            if (identifier) {
                SRGBaseRequest *request = [[[SRGDataProvider.currentDataProvider radioLatestEpisodesForVendor:vendor channelUid:identifier withCompletionBlock:^(NSArray<SRGMedia *> * _Nullable medias, SRGPage * _Nonnull page, SRGPage * _Nullable nextPage, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
                    [requestQueue reportError:error];
                    paginatedItemListCompletionBlock(medias, page, nextPage, HTTPResponse, error);
                }] requestWithPageSize:pageSize] requestWithPage:page];
                [requestQueue addRequest:request resume:YES];
            }
            break;
        }
            
        case HomeSectionRadioMostPopular: {
            NSString *identifier = self.identifier;
            if (identifier) {
                SRGBaseRequest *request = [[[SRGDataProvider.currentDataProvider radioMostPopularMediasForVendor:vendor channelUid:identifier withCompletionBlock:^(NSArray<SRGMedia *> * _Nullable medias, SRGPage * _Nonnull page, SRGPage * _Nullable nextPage, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
                    [requestQueue reportError:error];
                    paginatedItemListCompletionBlock(medias, page, nextPage, HTTPResponse, error);
                }] requestWithPageSize:pageSize] requestWithPage:page];
                [requestQueue addRequest:request resume:YES];
            }
            break;
        }
            
        case HomeSectionRadioLatest: {
            NSString *identifier = self.identifier;
            if (identifier) {
                SRGBaseRequest *request = [[[SRGDataProvider.currentDataProvider radioLatestMediasForVendor:vendor channelUid:identifier withCompletionBlock:^(NSArray<SRGMedia *> * _Nullable medias, SRGPage * _Nonnull page, SRGPage * _Nullable nextPage, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
                    [requestQueue reportError:error];
                    paginatedItemListCompletionBlock(medias, page, nextPage, HTTPResponse, error);
                }] requestWithPageSize:pageSize] requestWithPage:page];
                [requestQueue addRequest:request resume:YES];
            }
            break;
        }
            
        case HomeSectionRadioLatestVideos: {
            NSString *identifier = self.identifier;
            if (identifier) {
                SRGBaseRequest *request = [[[SRGDataProvider.currentDataProvider radioLatestVideosForVendor:vendor channelUid:identifier withCompletionBlock:^(NSArray<SRGMedia *> * _Nullable medias, SRGPage * _Nonnull page, SRGPage * _Nullable nextPage, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
                    [requestQueue reportError:error];
                    paginatedItemListCompletionBlock(medias, page, nextPage, HTTPResponse, error);
                }] requestWithPageSize:pageSize] requestWithPage:page];
                [requestQueue addRequest:request resume:YES];
            }
            break;
        }
            
        case HomeSectionRadioAllShows: {
            NSString *identifier = self.identifier;
            if (identifier) {
                SRGBaseRequest *request = [[[SRGDataProvider.currentDataProvider radioShowsForVendor:vendor channelUid:identifier withCompletionBlock:^(NSArray<SRGShow *> * _Nullable shows, SRGPage * _Nonnull page, SRGPage * _Nullable nextPage, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
                    [requestQueue reportError:error];
                    paginatedItemListCompletionBlock(shows, page, nextPage, HTTPResponse, error);
                }] requestWithPageSize:SRGDataProviderUnlimitedPageSize] requestWithPage:page];
                [requestQueue addRequest:request resume:YES];
            }
            break;
        }
            
        default: {
            break;
        }
    }
}

#pragma mark Description

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p; homeSection = %@; object = %@; title = %@; items = %@>",
            self.class,
            self,
            @(self.homeSection),
            self.object,
            self.title,
            self.items];
}

@end
