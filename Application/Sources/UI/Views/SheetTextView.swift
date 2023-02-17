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
        VStack(spacing: 0) {
            Handle()
                .frame(height: 50)
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
            .padding(.bottom, 28)
        }
        .background(Color.srgGray23)
    }
    
    /// Behavior: h-exp, v-exp
    struct Handle: View {
        var body: some View {
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Grabber()
                    Spacer()
                }
                Spacer()
            }
        }
        
        /// Behavior: h-hug, v-hug
        private struct Grabber: View {
            var body: some View {
                RoundedRectangle(cornerRadius: 2.5)
                    .frame(width: 38, height: 5)
                    .foregroundColor(.srgGrayC7)
            }
        }
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
