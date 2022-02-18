//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGAppearanceSwift
import SwiftUI

// MARK: Cell

struct LoadingCell: View {
    @State private var appeared = false
    
    var body: some View {
        Color(appeared ? .srgGray33 : .srgGray23)
            .animation(Animation.linear(duration: 1).repeatForever(autoreverses: true), value: appeared)
            .onAppear {
                appeared = true
            }
    }
}

// MARK: Preview

struct LoadingCell_Previews: PreviewProvider {
    private static let height: CGFloat = constant(iOS: 105, tvOS: 120)
    
    static var previews: some View {
        LoadingCell()
            .previewLayout(.fixed(width: 500, height: height))
    }
}
