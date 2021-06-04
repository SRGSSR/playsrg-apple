//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import Foundation

func ApplicationSettingSectionWideSupportEnabled() -> Bool {
    return UserDefaults.standard.bool(forKey: PlaySRGSettingSectionWideSupportEnabled)
}
