//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "TVChannel.h"

@interface TVChannel ()

@end

@implementation TVChannel

@end

UIImage *TVChannelLogo22Image(TVChannel *tvChannel)
{
    return [UIImage imageNamed:[NSString stringWithFormat:@"logo_%@-22", tvChannel.resourceUid]] ?: [UIImage imageNamed:@"tv-22"];
}

UIImage *TVChannelLogo32Image(TVChannel *tvChannel)
{
    return [UIImage imageNamed:[NSString stringWithFormat:@"logo_%@-32", tvChannel.resourceUid]] ?: [UIImage imageNamed:@"tv-32"];
}

UIImage *TVChannelLogo60Image(TVChannel *tvChannel)
{
    return [UIImage imageNamed:[NSString stringWithFormat:@"logo_%@-60", tvChannel.resourceUid]];
}
