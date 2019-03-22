//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGChannel+PlaySRG.h"

#import "ApplicationConfiguration.h"

#import <libextobjc/libextobjc.h>

@implementation SRGChannel (PlaySRG)

- (UIImage *)play_banner22Image
{
    if (self.transmission == SRGTransmissionRadio) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == %@", @keypath(RadioChannel.new, uid), self.uid];
        RadioChannel *radioChannel = [ApplicationConfiguration.sharedApplicationConfiguration.radioChannels filteredArrayUsingPredicate:predicate].firstObject;
        return RadioChannelBanner22Image(radioChannel);
    }
    else {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == %@", @keypath(TVChannel.new, uid), self.uid];
        TVChannel *tvChannel = [ApplicationConfiguration.sharedApplicationConfiguration.tvChannels filteredArrayUsingPredicate:predicate].firstObject;
        return TVChannelBanner22Image(tvChannel);
    }
}

@end
