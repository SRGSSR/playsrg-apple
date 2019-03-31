//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "History.h"

#import "ApplicationConfiguration.h"
#import "Download.h"
#import "NSTimer+PlaySRG.h"

#import <GoogleCast/GoogleCast.h>
#import <SRGLetterbox/SRGLetterbox.h>
#import <SRGUserData/SRGUserData.h>

static NSMutableDictionary<NSString *, NSNumber *> *s_cachedProgresses;
static NSMutableDictionary<NSString *, NSString *> *s_tasks;
static NSTimer *s_trackerTimer;

#pragma mark Helpers

static float HistoryPlaybackProgress(NSTimeInterval playbackPosition, double durationInSeconds)
{
    NSTimeInterval durationWithToleranceInSeconds = fmax(durationInSeconds - ApplicationConfigurationEffectiveEndTolerance(durationInSeconds), 0.f);
    if (durationWithToleranceInSeconds == 0.f) {
        return 1.f;
    }
    else {
        return fmax(fmin(playbackPosition / durationWithToleranceInSeconds, 1.f), 0.f);
    }
}

SRGPosition *HistoryResumePlaybackPositionForMedia(SRGMedia *media)
{
    // Always start at the default location for livestreams and scheduled livestreams
    if (media.contentType == SRGContentTypeLivestream || media.contentType == SRGContentTypeScheduledLivestream) {
        return nil;
    }
    
    // Allow faster seek to an earlier position, but not to a later position (playback for a history entry should not resume with
    // content the user has not seen yet)
    SRGHistoryEntry *historyEntry = [SRGUserData.currentUserData.history historyEntryWithUid:media.URN];
    if (historyEntry && ! historyEntry.discarded) {
        return [SRGPosition positionBeforeTime:historyEntry.lastPlaybackTime];
    }
    else {
        return nil;
    }
}

static SRGMedia *HistoryChapterMedia(SRGLetterboxController *controller)
{
    SRGMediaComposition *mediaComposition = controller.mediaComposition;
    if (mediaComposition) {
        return [mediaComposition mediaForSubdivision:mediaComposition.mainChapter];
    }
    
    SRGMedia *media = controller.media;
    if (media && [Download downloadForMedia:media]) {
        return media;
    }
    
    return nil;
}

#pragma mark Player tracker

__attribute__((constructor)) static void HistoryPlayerTrackerInit(void)
{
    s_cachedProgresses = [NSMutableDictionary dictionary];
    s_tasks = [NSMutableDictionary dictionary];
    
    s_trackerTimer = [NSTimer play_timerWithTimeInterval:1. repeats:YES block:^(NSTimer * _Nonnull timer) {
        NSString *deviceUid = UIDevice.currentDevice.name;
        
        GCKSession *session = [GCKCastContext sharedInstance].sessionManager.currentSession;
        if (session) {
            GCKMediaStatus *mediaStatus = session.remoteMediaClient.mediaStatus;
            if (mediaStatus.playerState != GCKMediaPlayerStatePlaying) {
                return;
            }
            
            NSString *URN = mediaStatus.mediaInformation.contentID;
            if (! URN) {
                return;
            }
            
            NSTimeInterval streamPosition = mediaStatus.streamPosition;
            [SRGUserData.currentUserData.history saveHistoryEntryForUid:URN withLastPlaybackTime:CMTimeMakeWithSeconds(streamPosition, NSEC_PER_SEC) deviceUid:deviceUid completionBlock:nil];
        }
        else {
            SRGLetterboxController *letterboxController = SRGLetterboxService.sharedService.controller;
            if (letterboxController.playbackState != SRGMediaPlayerPlaybackStatePlaying) {
                return;
            }
            
            SRGMedia *chapterMedia = HistoryChapterMedia(letterboxController);
            if (! chapterMedia || chapterMedia.contentType == SRGContentTypeLivestream) {
                return;
            }
            
            CMTime currentTime = letterboxController.currentTime;
            CMTime chapterPlaybackTime = (chapterMedia.contentType != SRGContentTypeScheduledLivestream && CMTIME_IS_VALID(currentTime)) ? currentTime : kCMTimeZero;
            
            // Save the segment position.
            SRGSubdivision *subdivision = letterboxController.subdivision;
            if ([subdivision isKindOfClass:SRGSegment.class]) {
                SRGSegment *segment = (SRGSegment *)subdivision;
                CMTime segmentPlaybackTime = CMTimeMaximum(CMTimeSubtract(chapterPlaybackTime, CMTimeMakeWithSeconds(segment.markIn / 1000., NSEC_PER_SEC)), kCMTimeZero);
                [SRGUserData.currentUserData.history saveHistoryEntryForUid:segment.URN withLastPlaybackTime:segmentPlaybackTime deviceUid:deviceUid completionBlock:nil];
            }
            
            // Save the main full-length position (update after the segment so that full-length entries are always more recent than corresponding
            // segment entries)
            [SRGUserData.currentUserData.history saveHistoryEntryForUid:chapterMedia.URN withLastPlaybackTime:chapterPlaybackTime deviceUid:deviceUid completionBlock:nil];
        }
    }];
}

#pragma mark Media metadata functions

static BOOL HistoryIsProgressForMediaMetadataTracked(id<SRGMediaMetadata> mediaMetadata)
{
    return mediaMetadata && mediaMetadata.duration > 0. && mediaMetadata.contentType != SRGContentTypeLivestream && mediaMetadata.contentType != SRGContentTypeScheduledLivestream;
}

static float HistoryPlaybackProgressForMediaMetadataHistoryEntry(SRGHistoryEntry *historyEntry, id<SRGMediaMetadata> mediaMetadata)
{
    NSCParameterAssert(historyEntry);
    
    return ! historyEntry.discarded ? HistoryPlaybackProgress(CMTimeGetSeconds(historyEntry.lastPlaybackTime), mediaMetadata.duration / 1000.) : 0.f;
}

float HistoryPlaybackProgressForMediaMetadata(id<SRGMediaMetadata> mediaMetadata)
{
    if (HistoryIsProgressForMediaMetadataTracked(mediaMetadata)) {
        SRGHistoryEntry *historyEntry = [SRGUserData.currentUserData.history historyEntryWithUid:mediaMetadata.URN];
        return historyEntry ? HistoryPlaybackProgressForMediaMetadataHistoryEntry(historyEntry, mediaMetadata) : 0.f;
    }
    else {
        return 0.f;
    }
}

void HistoryPlaybackProgressForMediaMetadataAsync(id<SRGMediaMetadata> mediaMetadata, void (^update)(float progress))
{
    if (! HistoryIsProgressForMediaMetadataTracked(mediaMetadata)) {
        update(0.f);
        return;
    }
    
    NSString *taskHandle = s_tasks[mediaMetadata.URN];
    if (taskHandle) {
        [SRGUserData.currentUserData.history cancelTaskWithHandle:taskHandle];
    }
    
    s_tasks[mediaMetadata.URN] = [SRGUserData.currentUserData.history historyEntryWithUid:mediaMetadata.URN completionBlock:^(SRGHistoryEntry * _Nullable historyEntry, NSError * _Nullable error) {
        if (error) {
            return;
        }
        
        float progress = historyEntry ? HistoryPlaybackProgressForMediaMetadataHistoryEntry(historyEntry, mediaMetadata) : 0.f;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            s_cachedProgresses[mediaMetadata.URN] = (progress > 0.f) ? @(progress) : nil;
            s_tasks[mediaMetadata.URN] = nil;
            
            update(progress);
        });
    }];
    
    NSNumber *cachedProgress = s_cachedProgresses[mediaMetadata.URN];
    update(cachedProgress.floatValue);
}

#pragma mark Favorite functions

static BOOL HistoryIsProgressForFavoriteTracked(Favorite *favorite)
{
    return favorite && favorite.type == FavoriteTypeMedia && favorite.duration > 0. && favorite.mediaContentType != FavoriteMediaContentTypeLive && favorite.mediaContentType != FavoriteMediaContentTypeScheduledLive;
}

static float HistoryPlaybackProgressForFavoriteHistoryEntry(SRGHistoryEntry *historyEntry, Favorite *favorite)
{
    NSCParameterAssert(historyEntry);
    
    return ! historyEntry.discarded ? HistoryPlaybackProgress(CMTimeGetSeconds(historyEntry.lastPlaybackTime), favorite.duration / 1000.) : 0.f;
}

float HistoryPlaybackProgressForFavorite(Favorite *favorite)
{
    if (HistoryIsProgressForFavoriteTracked(favorite)) {
        SRGHistoryEntry *historyEntry = [SRGUserData.currentUserData.history historyEntryWithUid:favorite.mediaURN];
        return historyEntry ? HistoryPlaybackProgressForFavoriteHistoryEntry(historyEntry, favorite) : 0.f;
    }
    else {
        return 0.f;
    }
}

void HistoryPlaybackProgressForFavoriteAsync(Favorite *favorite, void (^update)(float progress))
{
    if (! HistoryIsProgressForFavoriteTracked(favorite)) {
        update(0.f);
        return;
    }
    
    NSString *taskHandle = s_tasks[favorite.mediaURN];
    if (taskHandle) {
        [SRGUserData.currentUserData.history cancelTaskWithHandle:taskHandle];
    }
    
    s_tasks[favorite.mediaURN] = [SRGUserData.currentUserData.history historyEntryWithUid:favorite.mediaURN completionBlock:^(SRGHistoryEntry * _Nullable historyEntry, NSError * _Nullable error) {
        if (error) {
            return;
        }
        
        float progress = historyEntry ? HistoryPlaybackProgressForFavoriteHistoryEntry(historyEntry, favorite) : 0.f;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            s_cachedProgresses[favorite.mediaURN] = (progress > 0.f) ? @(progress) : nil;
            s_tasks[favorite.mediaURN] = nil;
            
            update(progress);
        });
    }];
    
    NSNumber *cachedProgress = s_cachedProgresses[favorite.mediaURN];
    update(cachedProgress.floatValue);
}
