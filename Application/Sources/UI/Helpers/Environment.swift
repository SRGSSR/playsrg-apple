//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

/**
 *  Selection state internal environment key.
 */
private struct SelectedKey: EnvironmentKey {
    static let defaultValue = false
}

/**
 *  Custom environment keys.
 */
extension EnvironmentValues {
    /**
     *  Selection state.
     */
    var isSelected: Bool {
        get {
            self[SelectedKey.self]
        }
        set {
            self[SelectedKey.self] = newValue
        }
    }
}
