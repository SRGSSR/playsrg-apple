//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

/**
 *  Editing state internal environment key.
 */
private struct EditingKey: EnvironmentKey {
    static let defaultValue = false
}

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
     *  Editing state.
     */
    var isEditing: Bool {
        get {
            self[EditingKey.self]
        }
        set {
            self[EditingKey.self] = newValue
        }
    }
    
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
