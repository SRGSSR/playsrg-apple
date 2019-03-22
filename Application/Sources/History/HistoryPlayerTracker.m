//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "HistoryPlayerTracker.h"

#import "Download.h"
#import "NSTimer+PlaySRG.h"

#import <SRGLetterbox/SRGLetterbox.h>
#import <SRGUserData/SRGUserData.h>

static NSTimer *s_timer;

static SRGMedia *HistoryPlayerTrackerMainChapterMedia(SRGLetterboxController *controller)
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

__attribute__((constructor)) static void HistoryPlayerTrackerInit(void)
{
    s_timer = [NSTimer play_timerWithTimeInterval:1. repeats:YES block:^(NSTimer * _Nonnull timer) {
        SRGLetterboxController *letterboxController = SRGLetterboxService.sharedService.controller;
        if (letterboxController.playbackState != SRGMediaPlayerPlaybackStatePlaying) {
            return;
        }
        
        SRGMedia *mainChapterMedia = HistoryPlayerTrackerMainChapterMedia(letterboxController);
        if (! mainChapterMedia || mainChapterMedia.contentType == SRGContentTypeLivestream) {
            return;
        }
        
        BOOL mainChapterMediaIsLivestream = (mainChapterMedia.contentType == SRGContentTypeLivestream || mainChapterMedia.contentType == SRGContentTypeScheduledLivestream);
        CMTime currentPlayerTime = letterboxController.currentTime;
        CMTime currentTime = (! mainChapterMediaIsLivestream && CMTIME_IS_VALID(currentPlayerTime)) ? currentPlayerTime : kCMTimeZero;
        SRGSubdivision *subdivision = letterboxController.subdivision;
        
        NSString *deviceUid = UIDevice.currentDevice.name;
        
        // Save the segment position.
        if ([subdivision isKindOfClass:SRGSegment.class] && ! [mainChapterMedia.URN isEqualToString:subdivision.URN]) {
            SRGSegment *segment = (SRGSegment *)subdivision;
            BOOL segmentIsLivestream = (segment.contentType == SRGContentTypeLivestream || segment.contentType == SRGContentTypeScheduledLivestream);
            CMTime lastPlaybackTime = (! segmentIsLivestream && ! mainChapterMediaIsLivestream) ? CMTimeSubtract(currentTime, CMTimeMakeWithSeconds(segment.markIn / 1000., NSEC_PER_SEC)) : kCMTimeZero;
            [SRGUserData.currentUserData.history saveHistoryEntryForUid:segment.URN withLastPlaybackTime:lastPlaybackTime deviceUid:deviceUid completionBlock:nil];
        }
        
        // Save the main full-length position (update after the segment so that full-length entries are always more recent than corresponding
        // segment entries)
        NSString *URN = mainChapterMedia.URN;
        [SRGUserData.currentUserData.history saveHistoryEntryForUid:URN withLastPlaybackTime:currentTime deviceUid:deviceUid completionBlock:nil];
    }];
}
