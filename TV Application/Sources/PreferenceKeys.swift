//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

/**
 *  Can be used to pass along focused state information from a child view to a parent,
 *  mostly useful if views outside a focusable view must know whether the focusable
 *  view is focused.
 */
struct FocusedKey: PreferenceKey {
    static var defaultValue: Bool = false
    
    static func reduce(value: inout Bool, nextValue: () -> Bool) {}
}
