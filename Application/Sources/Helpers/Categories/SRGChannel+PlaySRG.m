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
        ApplicationConfiguration *applicationConfiguration = ApplicationConfiguration.sharedApplicationConfiguration;
        NSArray<RadioChannel *> *radioChannels = [applicationConfiguration.radioChannels arrayByAddingObjectsFromArray:applicationConfiguration.ssatrChannels];
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == %@", @keypath(RadioChannel.new, uid), self.uid];
        RadioChannel *radioChannel = [radioChannels filteredArrayUsingPredicate:predicate].firstObject;
        return RadioChannelLogo32Image(radioChannel);
    }
    else {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == %@", @keypath(TVChannel.new, uid), self.uid];
        TVChannel *tvChannel = [ApplicationConfiguration.sharedApplicationConfiguration.tvChannels filteredArrayUsingPredicate:predicate].firstObject;
        return TVChannelLogo32Image(tvChannel);
    }
}

- (UIImage *)play_logo60Image
{
    if (self.transmission == SRGTransmissionRadio) {
        ApplicationConfiguration *applicationConfiguration = ApplicationConfiguration.sharedApplicationConfiguration;
        NSArray<RadioChannel *> *radioChannels = [applicationConfiguration.radioChannels arrayByAddingObjectsFromArray:applicationConfiguration.ssatrChannels];
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == %@", @keypath(RadioChannel.new, uid), self.uid];
        RadioChannel *radioChannel = [radioChannels filteredArrayUsingPredicate:predicate].firstObject;
        return RadioChannelLogo60Image(radioChannel);
    }
    else {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == %@", @keypath(TVChannel.new, uid), self.uid];
        TVChannel *tvChannel = [ApplicationConfiguration.sharedApplicationConfiguration.tvChannels filteredArrayUsingPredicate:predicate].firstObject;
        return TVChannelLogo60Image(tvChannel);
    }
}

@end
