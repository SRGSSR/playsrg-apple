//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#if DEBUG || NIGHTLY || BETA
    import ShowTime
#endif
import SRGLetterbox

final class PresenterMode: NSObject {
    @objc static func enable(_ enabled: Bool) {
        SRGLetterboxService.shared.isMirroredOnExternalScreen = enabled
        #if DEBUG || NIGHTLY || BETA
            ShowTime.enabled = enabled ? .always : .never
        #endif
    }
}
