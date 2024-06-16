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
        VStack(spacing: 18) {
            Handle {
                guard let viewController = UIApplication.shared.mainTopViewController else { return }
                viewController.dismiss(animated: true)
            }
            ScrollView(.vertical) {
                HStack(spacing: 0) {
                    Text(content)
                        .srgFont(.body)
                        .foregroundColor(.srgGrayD2)
                        .multilineTextAlignment(.leading)
                        .padding(.horizontal, 28)
                    Spacer(minLength: 0)
                }
            }
            .padding(.bottom, 28)
        }
        .background(Color.srgGray23)
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
