//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGDataProvider

extension SRGDataProvider {
    @objc static func play_imageScalingService(_ scalingService: SRGImageScalingService) -> SRGImageScalingService {
        return imageScalingService(scalingService)
    }
}

func imageScalingService(_ scalingService: SRGImageScalingService) -> SRGImageScalingService {
#if DEBUG || NIGHTLY || BETA
    return UserDefaults.standard.bool(forKey: PlaySRGSettingCentralizedImageServicePreferred) ? .centralized : scalingService
#else
    return scalingService
#endif
}
