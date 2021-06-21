//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGChannel+PlaySRG.h"

#import "ApplicationConfiguration.h"

@import libextobjc;

@implementation SRGChannel (PlaySRG)

- (UIImage *)play_largeLogoImage
{
    if (self.transmission == SRGTransmissionRadio) {
        return RadioChannelLargeLogoImage([ApplicationConfiguration.sharedApplicationConfiguration radioChannelForUid:self.uid]);
    }
    else {
        return TVChannelLargeLogoImage([ApplicationConfiguration.sharedApplicationConfiguration tvChannelForUid:self.uid]);
    }
}

@end
