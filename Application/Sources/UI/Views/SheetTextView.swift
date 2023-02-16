//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGAppearanceSwift
import SwiftUI

// MARK: View

/// Behavior: h-exp, v-exp
struct SheetTextView: View {
    let content: String
    
    var body: some View {
        ScrollView(.vertical) {
            HStack(spacing: 0) {
                Text(content)
                    .srgFont(.body)
                    .foregroundColor(.srgGrayC7)
                    .multilineTextAlignment(.leading)
                    .padding(.horizontal, 28)
                Spacer(minLength: 0)
            }
        }
        .padding(.vertical, 28)
    }
}

// MARK: Preview

struct FullTextView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            SheetTextView(content: "Short description.")
            SheetTextView(content: String.loremIpsum)
        }
        .frame(width: 375, height: 375)
        .previewLayout(.sizeThatFits)
    }
}
