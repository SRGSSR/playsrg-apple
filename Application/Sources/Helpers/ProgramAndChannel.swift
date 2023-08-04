//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGDataProviderModel

struct ProgramAndChannel: Hashable {
    let program: SRGProgram
    let channel: SRGChannel
    
    func programGuideImageUrl(size: SRGImageSize) -> URL? {
        if let image = program.image {
            return PlaySRG.url(for: image, size: size)
        }
        // Couldn't use channel image in Play SRG image service. Use raw image.
        else if let channelRawImage = channel.rawImage {
            return PlaySRG.url(for: channelRawImage, size: size)
        }
        else {
            return nil
        }
    }
}
