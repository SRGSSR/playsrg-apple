//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

struct LabeledButton: View {
    let icon: String
    let label: String
    let action: () -> Void
    
    @State private var isFocused: Bool = false
    
    var body: some View {
        VStack {
            Button(action: action) {
                Image(icon)
                    .foregroundColor(Color.white)
                    .reportFocusChanges()
            }
            Text(label)
                .srgFont(.regular, size: .subtitle)
                .foregroundColor(isFocused ? .white : .gray)
        }
        .onFocusChange { isFocused = $0 }
    }
}
