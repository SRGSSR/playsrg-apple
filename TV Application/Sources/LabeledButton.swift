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
                    .foregroundColor(isFocused ? .darkGray : .white)
                    .reportFocusChanges()
            }
            Text(label)
                .srgFont(.regular, size: .subtitle)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .foregroundColor(isFocused ? .white : .gray)
        }
        .frame(width: 120)
        .onFocusChange { isFocused = $0 }
    }
}

struct LabeledButton_Previews: PreviewProvider {
    static var previews: some View {
        HStack(alignment: .top) {
            LabeledButton(icon: "episodes-22", label: "Episodes", action: {})
            LabeledButton(icon: "favorite-22", label: "Watch later", action: {})
        }
    }
}
