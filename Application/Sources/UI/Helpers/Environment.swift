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
 *  UIKit focus state internal environment key.
 */
private struct UIKitFocusedKey: EnvironmentKey {
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
    
    /**
     *  UIKit focus state (if focus set by UIKit).
     */
    var isUIKitFocused: Bool {
        get {
            self[UIKitFocusedKey.self]
        }
        set {
            self[UIKitFocusedKey.self] = newValue
        }
    }
}
