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
    
    /**
     *  UIKit size class support for iOS and tvOS (`UserInterfaceSizeClass` is marked as unavailable for tvOS,
     *  unlike `UIUserInterfaceSizeClass`, leading to more preprocessor use than should be necessary).
     */
    var uiHorizontalSizeClass: UIUserInterfaceSizeClass {
        get {
#if os(iOS)
            return horizontalSizeClass == .compact ? .compact : .regular
#else
            return .regular
#endif
        }
    }
    
    var uiVerticalSizeClass: UIUserInterfaceSizeClass {
        get {
#if os(iOS)
            return verticalSizeClass == .compact ? .compact : .regular
#else
            return .regular
#endif
        }
    }
}
