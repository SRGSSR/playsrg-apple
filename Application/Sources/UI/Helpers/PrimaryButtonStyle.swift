//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

extension ButtonStyle where Self == PrimaryButtonStyle {
    static var primary: PrimaryButtonStyle {
        PrimaryButtonStyle()
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .srgFont(.H3)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .foregroundColor(.black)
            .background(.white)
            .clipShape(.capsule)
            .opacity(configuration.isPressed ? 0.8 : 1)
    }
}
