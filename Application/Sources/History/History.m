//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "History.h"

#import "ApplicationConfiguration.h"
#if TARGET_OS_IOS
#import "Download.h"
#endif
#import "NSTimer+PlaySRG.h"
#import "PlaySRG-Swift.h"

@import libextobjc;

#if TARGET_OS_IOS
@import GoogleCast;
#endif
@import SRGUserData;

static NSMutableDictionary<NSString *, NSNumber *> *s_cachedProgresses;
#if TARGET_OS_IOS
static NSTimer *s_trackerTimer;
#endif

static BOOL HistoryIsProgressForMediaTracked(SRGMedia *media);
static float HistoryPlaybackProgressForMediaHistoryEntry(SRGHistoryEntry *historyEntry, SRGMedia *media);

#pragma mark Helpers

float HistoryPlaybackProgress(NSTimeInterval playbackPosition, double durationInSeconds)
{
    NSTimeInterval durationWithToleranceInSeconds = fmax(durationInSeconds - ApplicationConfigurationEffectiveEndTolerance(durationInSeconds), 0.f);
    if (durationWithToleranceInSeconds == 0.f) {
        return 1.f;
    }
    else {
        return fmax(fmin(playbackPosition / durationWithToleranceInSeconds, 1.f), 0.f);
    }
}

BOOL HistoryContainsMedia(SRGMedia *media)
{
    SRGHistoryEntry *historyEntry = [SRGUserData.currentUserData.history historyEntryWithUid:media.URN];
    return historyEntry != nil;
}

SRGPosition *HistoryResumePlaybackPositionForMedia(SRGMedia *media)
{
    if (! HistoryIsProgressForMediaTracked(media)) {
        return nil;
    }
    
    SRGHistoryEntry *historyEntry = [SRGUserData.currentUserData.history historyEntryWithUid:media.URN];
    if (! historyEntry) {
        return nil;
    }
    
    // Start at the default location if the content was played entirely.
    if (HistoryPlaybackProgressForMediaHistoryEntry(historyEntry, media) == 1.f) {
        return nil;
    }
    
    // TODO: Fix stream issues (see https://github.com/SRGSSR/srgletterbox-apple/issues/245) then restore `positionBeforeTime:`
    //       which was the initially desired behavior.
    return [SRGPosition positionAtTime:historyEntry.lastPlaybackTime];
}

NSString *HistoryResumePlaybackPositionForMediaAsync(SRGMedia *media, void (^completion)(SRGPosition * _Nullable position))
{
    if (! HistoryIsProgressForMediaTracked(media)) {
        completion(nil);
        return nil;
    }
    
    return [SRGUserData.currentUserData.history historyEntryWithUid:media.URN completionBlock:^(SRGHistoryEntry * _Nullable historyEntry, NSError * _Nullable error) {
        // Start at the default location if the content was played entirely.
        if (HistoryPlaybackProgressForMediaHistoryEntry(historyEntry, media) == 1.f) {
            completion(nil);
            return;
        }
        
        // TODO: Fix stream issues (see https://github.com/SRGSSR/srgletterbox-apple/issues/245) then restore `positionBeforeTime:`
        //       which was the initially desired behavior.
        SRGPosition *position = [SRGPosition positionAtTime:historyEntry.lastPlaybackTime];
        completion(position);
    }];
}

BOOL HistoryCanResumePlaybackForMediaAndPosition(NSTimeInterval playbackPosition, SRGMedia *media)
{
    return HistoryIsProgressForMediaTracked(media) && [media blockingReasonAtDate:NSDate.date] == SRGBlockingReasonNone && HistoryPlaybackProgress(playbackPosition, media.duration / 1000.) != 1.f;
}

BOOL HistoryCanResumePlaybackForMedia(SRGMedia *media)
{
    return HistoryIsProgressForMediaTracked(media) && [media blockingReasonAtDate:NSDate.date] == SRGBlockingReasonNone && HistoryPlaybackProgressForMedia(media) != 1.f;
}

NSString *HistoryCanResumePlaybackForMediaAsync(SRGMedia *media, void (^completion)(BOOL canResume))
{
    if (! HistoryIsProgressForMediaTracked(media) || [media blockingReasonAtDate:NSDate.date] != SRGBlockingReasonNone) {
        completion(NO);
        return nil;
    }
    
    return HistoryPlaybackProgressForMediaAsync(media, ^(float progress) {
        completion(progress != 1.f);
    });
}

void HistoryRemoveMedias(NSArray<SRGMedia *> *medias, void (^completion)(NSError * _Nullable error))
{
    NSString *keyPath = [NSString stringWithFormat:@"@distinctUnionOfObjects.%@", @keypath(SRGMedia.new, URN)];
    NSArray<NSString *> *URNs = [medias valueForKeyPath:keyPath];
    [SRGUserData.currentUserData.history discardHistoryEntriesWithUids:URNs completionBlock:completion];
    [UserInteractionEvent removeFromHistory:medias];
}

static SRGMedia *HistoryChapterMedia(SRGLetterboxController *controller)
{
    SRGMediaComposition *mediaComposition = controller.mediaComposition;
    if (mediaComposition) {
        return [mediaComposition mediaForSubdivision:mediaComposition.mainChapter];
    }
    
#if TARGET_OS_IOS
    SRGMedia *media = controller.media;
    if (media && [Download downloadForMedia:media]) {
        return media;
    }
#endif
    
    return nil;
}

#pragma mark Player tracker

/**
 *  Update progress information based on the provided controller.
 */
void HistoryUpdateLetterboxPlaybackProgress(SRGLetterboxController *letterboxController)
{
    if (letterboxController.playbackState != SRGMediaPlayerPlaybackStatePlaying) {
        return;
    }
    
    SRGMedia *chapterMedia = HistoryChapterMedia(letterboxController);
    if (! chapterMedia || chapterMedia.contentType == SRGContentTypeLivestream) {
        return;
    }
    
    CMTime currentTime = letterboxController.currentTime;
    CMTime chapterPlaybackTime = (chapterMedia.contentType != SRGContentTypeScheduledLivestream && CMTIME_IS_VALID(currentTime)) ? currentTime : kCMTimeZero;
    NSString *deviceUid = UIDevice.currentDevice.name;
    
    // Save the segment position.
    SRGSubdivision *subdivision = letterboxController.subdivision;
    if ([subdivision isKindOfClass:SRGSegment.class]) {
        SRGSegment *segment = (SRGSegment *)subdivision;
        CMTime segmentPlaybackTime = CMTimeMaximum(CMTimeSubtract(chapterPlaybackTime, CMTimeMakeWithSeconds(segment.markIn / 1000., NSEC_PER_SEC)), kCMTimeZero);
        [SRGUserData.currentUserData.history saveHistoryEntryWithUid:segment.URN lastPlaybackTime:segmentPlaybackTime deviceUid:deviceUid completionBlock:nil];
    }
    
    // Save the main full-length position (update after the segment so that full-length entries are always more recent than corresponding
    // segment entries)
    [SRGUserData.currentUserData.history saveHistoryEntryWithUid:chapterMedia.URN lastPlaybackTime:chapterPlaybackTime deviceUid:deviceUid completionBlock:nil];
    [UserInteractionEvent addToHistory:@[chapterMedia]];
}

#if TARGET_OS_IOS

/**
 *  Return YES if a cast session is active and update the progress if needed.
 */
static BOOL HistoryUpdateGoogleCastPlaybackProgress(void)
{
    GCKSession *session = [GCKCastContext sharedInstance].sessionManager.currentSession;
    if (! session) {
        return NO;
    }
    
    GCKRemoteMediaClient *remoteMediaClient = session.remoteMediaClient;
    GCKMediaStatus *mediaStatus = remoteMediaClient.mediaStatus;
    if (mediaStatus.playerState != GCKMediaPlayerStatePlaying) {
        return YES;
    }
    
    // Only for on-demand streams
    GCKMediaInformation *mediaInformation = mediaStatus.mediaInformation;
    if (mediaInformation.streamType != GCKMediaStreamTypeBuffered) {
        return YES;
    }
    
    NSString *URN = mediaInformation.contentID;
    if (! URN) {
        return YES;
    }
    
    // Use approximate value. The value in GCKMediaStatus is updated from time to time. The approximateStreamPosition
    // interpolates between known values to get a smoother progress
    NSTimeInterval streamPosition = remoteMediaClient.approximateStreamPosition;
    NSString *deviceUid = UIDevice.currentDevice.name;
    [SRGUserData.currentUserData.history saveHistoryEntryWithUid:URN lastPlaybackTime:CMTimeMakeWithSeconds(streamPosition, NSEC_PER_SEC) deviceUid:deviceUid completionBlock:nil];
    
    return YES;
}

#endif

__attribute__((constructor)) static void HistoryPlayerTrackerInit(void)
{
    s_cachedProgresses = [NSMutableDictionary dictionary];
    
#if TARGET_OS_IOS
    s_trackerTimer = [NSTimer play_timerWithTimeInterval:1. repeats:YES block:^(NSTimer * _Nonnull timer) {
        if (HistoryUpdateGoogleCastPlaybackProgress()) {
            return;
        }
        
        SRGLetterboxController *letterboxController = SRGLetterboxService.sharedService.controller;
        HistoryUpdateLetterboxPlaybackProgress(letterboxController);
    }];
#endif
}

#pragma mark Functions

static BOOL HistoryIsProgressForMediaTracked(SRGMedia *media)
{
    return media && media.duration > 0. && media.contentType != SRGContentTypeLivestream && media.contentType != SRGContentTypeScheduledLivestream;
}

static float HistoryPlaybackProgressForMediaHistoryEntry(SRGHistoryEntry *historyEntry, SRGMedia *media)
{
    NSCParameterAssert(historyEntry);
    return HistoryPlaybackProgress(CMTimeGetSeconds(historyEntry.lastPlaybackTime), media.duration / 1000.);
}

float HistoryPlaybackProgressForMedia(SRGMedia *media)
{
    if (HistoryIsProgressForMediaTracked(media)) {
        SRGHistoryEntry *historyEntry = [SRGUserData.currentUserData.history historyEntryWithUid:media.URN];
        return historyEntry ? HistoryPlaybackProgressForMediaHistoryEntry(historyEntry, media) : 0.f;
    }
    else {
        return 0.f;
    }
}

NSString *HistoryPlaybackProgressForMediaAsync(SRGMedia *media, void (^update)(float progress))
{
    if (! HistoryIsProgressForMediaTracked(media)) {
        update(0.f);
        return nil;
    }
    
    NSString *handle = [SRGUserData.currentUserData.history historyEntryWithUid:media.URN completionBlock:^(SRGHistoryEntry * _Nullable historyEntry, NSError * _Nullable error) {
        if (error) {
            return;
        }
        
        float progress = historyEntry ? HistoryPlaybackProgressForMediaHistoryEntry(historyEntry, media) : 0.f;
        s_cachedProgresses[media.URN] = (progress > 0.f) ? @(progress) : nil;
        update(progress);
    }];
    
    NSNumber *cachedProgress = s_cachedProgresses[media.URN];
    update(cachedProgress.floatValue);
    
    return handle;
}

void HistoryPlaybackProgressAsyncCancel(NSString *handle)
{
    if (handle) {
        [SRGUserData.currentUserData.history cancelTaskWithHandle:handle];
    }
}
