//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "GoogleCast.h"

#import "PlayErrors.h"

#import <CoconutKit/CoconutKit.h>

BOOL GoogleCastIsPossible(SRGMediaComposition *mediaComposition, NSError **pError)
{
    GCKDevice *castDevice = [GCKCastContext sharedInstance].sessionManager.currentCastSession.device;
    if (! castDevice) {
        if (pError) {
            *pError = [NSError errorWithDomain:PlayErrorDomain
                                          code:PlayErrorCodeReceiver
                          localizedDescription:NSLocalizedString(@"No Google Cast receiver is available.", @"Message displayed if no Google Cast receiver is available")];
        }
        return NO;
    }
    
    SRGChapter *mainChapter = mediaComposition.mainChapter;
    SRGBlockingReason blockingReason = [mainChapter blockingReasonAtDate:NSDate.date];
    
    // Check device compatibility
    if (mainChapter.mediaType == SRGMediaTypeVideo && ! [castDevice hasCapabilities:GCKDeviceCapabilityVideoOut]) {
        if (pError) {
            *pError = [NSError errorWithDomain:PlayErrorDomain
                                          code:PlayErrorCodeReceiver
                          localizedDescription:NSLocalizedString(@"The Google Cast receiver cannot play videos.", @"Message displayed if the Google Cast receiver cannot play videos")];
        }
        return NO;
    }
    else if (mainChapter.mediaType == SRGMediaTypeAudio && ! [castDevice hasCapabilities:GCKDeviceCapabilityAudioOut]) {
        if (pError) {
            *pError = [NSError errorWithDomain:PlayErrorDomain
                                          code:PlayErrorCodeReceiver
                          localizedDescription:NSLocalizedString(@"The Google Cast receiver cannot play audios.", @"Message displayed if the Google Cast receiver cannot play audios")];
        }
        return NO;
    }
    else if (blockingReason != SRGBlockingReasonNone) {
        if (pError) {
            *pError = [NSError errorWithDomain:PlayErrorDomain
                                          code:PlayErrorCodeForbidden
                          localizedDescription:NSLocalizedString(@"This content is not allowed to be played with Google Cast.", @"Message displayed when attempting to play some content not allowed to be played with Google Cast")];
        }
        return NO;
    }
    
    // Do not let the content be played if it contains a blocked segment
    NSPredicate *blockedSegmentsPredicate = [NSPredicate predicateWithBlock:^BOOL(SRGSegment * _Nullable segment, NSDictionary<NSString *,id> * _Nullable bindings) {
        return [segment blockingReasonAtDate:NSDate.date] != SRGBlockingReasonNone;
    }];
    NSArray<SRGSegment *> *blockedSegments = [mainChapter.segments filteredArrayUsingPredicate:blockedSegmentsPredicate];
    if (blockedSegments.count != 0) {
        if (pError) {
            *pError = [NSError errorWithDomain:PlayErrorDomain
                                          code:PlayErrorCodeForbidden
                          localizedDescription:NSLocalizedString(@"This content is not allowed to be played with Google Cast.", @"Message displayed when attempting to play some content not allowed to be played with Google Cast")];
        }
        return NO;
    }
    
    // Do not let the content be played if it is a full-length and a chapter related to it is blocked
    NSPredicate *blockedAffiliatedChaptersPredicate = [NSPredicate predicateWithBlock:^BOOL(SRGChapter * _Nullable chapter, NSDictionary<NSString *,id> * _Nullable bindings) {
        return [chapter.fullLengthURN isEqual:mainChapter.URN] && [chapter blockingReasonAtDate:NSDate.date] != SRGBlockingReasonNone;
    }];
    NSArray<SRGChapter *> *blockedAffiliatedChapters = [mediaComposition.chapters filteredArrayUsingPredicate:blockedAffiliatedChaptersPredicate];
    if (blockedAffiliatedChapters.count != 0) {
        if (pError) {
            *pError = [NSError errorWithDomain:PlayErrorDomain
                                          code:PlayErrorCodeForbidden
                          localizedDescription:NSLocalizedString(@"This content is not allowed to be played with Google Cast.", @"Message displayed when attempting to play some content not allowed to be played with Google Cast")];
        }
        return NO;
    }
    
    return YES;
}
