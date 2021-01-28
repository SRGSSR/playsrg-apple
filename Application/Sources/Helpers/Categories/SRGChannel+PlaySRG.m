//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGChannel+PlaySRG.h"

#import "ApplicationConfiguration.h"

@import libextobjc;

@implementation SRGChannel (PlaySRG)

- (UIImage *)play_logo32Image
{
    if (self.transmission == SRGTransmissionRadio) {
        return RadioChannelLogo32Image([ApplicationConfiguration.sharedApplicationConfiguration radioChannelForUid:self.uid]);
    }
    else {
        return TVChannelLogo32Image([ApplicationConfiguration.sharedApplicationConfiguration tvChannelForUid:self.uid]);
    }
}

- (UIImage *)play_logo60Image
{
    if (self.transmission == SRGTransmissionRadio) {
        return RadioChannelLogo60Image([ApplicationConfiguration.sharedApplicationConfiguration radioChannelForUid:self.uid]);
    }
    else {
        return TVChannelLogo60Image([ApplicationConfiguration.sharedApplicationConfiguration tvChannelForUid:self.uid]);
    }
}

@end
