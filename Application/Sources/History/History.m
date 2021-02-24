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

#if TARGET_OS_IOS
@import GoogleCast;
#endif
@import SRGUserData;

static NSMutableDictionary<NSString *, NSNumber *> *s_cachedProgresses;
#if TARGET_OS_IOS
static NSTimer *s_trackerTimer;
#endif

static BOOL HistoryIsProgressForMediaMetadataTracked(id<SRGMediaMetadata> mediaMetadata);
static float HistoryPlaybackProgressForMediaMetadataHistoryEntry(SRGHistoryEntry *historyEntry, id<SRGMediaMetadata> mediaMetadata);

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

SRGPosition *HistoryResumePlaybackPositionForMedia(SRGMedia *media)
{
    if (! HistoryIsProgressForMediaMetadataTracked(media)) {
        return nil;
    }
    
    // Allow faster seek to an earlier position, but not to a later position (playback for a history entry should not resume with
    // content the user has not seen yet)
    SRGHistoryEntry *historyEntry = [SRGUserData.currentUserData.history historyEntryWithUid:media.URN];
    if (! historyEntry) {
        return nil;
    }
    
    // Start at the default location if the content was played entirely.
    if (HistoryPlaybackProgressForMediaMetadataHistoryEntry(historyEntry, media) == 1.f) {
        return nil;
    }
    
    return [SRGPosition positionBeforeTime:historyEntry.lastPlaybackTime];
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

#pragma mark Media metadata functions

static BOOL HistoryIsProgressForMediaMetadataTracked(id<SRGMediaMetadata> mediaMetadata)
{
    return mediaMetadata && mediaMetadata.duration > 0. && mediaMetadata.contentType != SRGContentTypeLivestream && mediaMetadata.contentType != SRGContentTypeScheduledLivestream;
}

static float HistoryPlaybackProgressForMediaMetadataHistoryEntry(SRGHistoryEntry *historyEntry, id<SRGMediaMetadata> mediaMetadata)
{
    NSCParameterAssert(historyEntry);
    return HistoryPlaybackProgress(CMTimeGetSeconds(historyEntry.lastPlaybackTime), mediaMetadata.duration / 1000.);
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

NSString *HistoryPlaybackProgressForMediaMetadataAsync(id<SRGMediaMetadata> mediaMetadata, void (^update)(float progress))
{
    if (! HistoryIsProgressForMediaMetadataTracked(mediaMetadata)) {
        update(0.f);
        return nil;
    }
    
    NSString *handle = [SRGUserData.currentUserData.history historyEntryWithUid:mediaMetadata.URN completionBlock:^(SRGHistoryEntry * _Nullable historyEntry, NSError * _Nullable error) {
        if (error) {
            return;
        }
        
        float progress = historyEntry ? HistoryPlaybackProgressForMediaMetadataHistoryEntry(historyEntry, mediaMetadata) : 0.f;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            s_cachedProgresses[mediaMetadata.URN] = (progress > 0.f) ? @(progress) : nil;
            update(progress);
        });
    }];
    
    NSNumber *cachedProgress = s_cachedProgresses[mediaMetadata.URN];
    update(cachedProgress.floatValue);
    
    return handle;
}

void HistoryPlaybackProgressAsyncCancel(NSString *handle)
{
    if (handle) {
        [SRGUserData.currentUserData.history cancelTaskWithHandle:handle];
    }
}
