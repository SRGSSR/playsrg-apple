//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGAppearanceSwift
import SwiftUI

// MARK: View

/// Behavior: h-exp, v-hug
struct ShowButton: View {
    private let show: SRGShow
    private let isFavorite: Bool
    private let action: () -> Void
    
    @State private var isFocused = false
    
    init(show: SRGShow, isFavorite: Bool, action: @escaping () -> Void) {
        self.show = show
        self.isFavorite = isFavorite
        self.action = action
    }
    
    private var imageUrl: URL? {
        return url(for: show.image, size: .small)
    }
    
    private var favoriteIcon: ImageResource {
        return isFavorite ? .favoriteFull : .favorite
    }
    
    private var accessibilityLabel: String {
        return "\(show.title), \(PlaySRGAccessibilityLocalizedString("More episodes", comment: "Button to access more episodes"))"
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                ImageView(source: imageUrl)
                    .aspectRatio(16 / 9, contentMode: .fit)
                VStack(alignment: .leading, spacing: 2) {
                    Text(show.title)
                        .srgFont(.H4)
                        .lineLimit(2)
                    Text(NSLocalizedString("More episodes", comment: "Button to access more episodes"))
                        .srgFont(.subtitle1)
                        .foregroundColor(.srgGrayD2)
                    Spacer()
                }
                .padding(.vertical, 2)
                .frame(maxWidth: .infinity, alignment: .leading)
                Image(favoriteIcon)
                    .padding(.trailing, 8)
            }
            .frame(height: 80)
            .onParentFocusChange { isFocused = $0 }
        }
        .buttonStyle(FlatButtonStyle(focused: isFocused, noPadding: true))
        .accessibilityElement(label: accessibilityLabel, traits: .isButton)
    }
}

// MARK: Preview

struct ShowButton_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ShowButton(show: Mock.show(), isFavorite: false, action: {})
                .padding()
                .previewLayout(.fixed(width: 360, height: 80))
        }
    }
}
