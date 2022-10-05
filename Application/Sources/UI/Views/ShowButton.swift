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
    private let accessibilityLabel: String
    private let accessibilityHint: String?
    private let action: () -> Void
    
    @State private var isFocused = false
    
    init(show: SRGShow, isFavorite: Bool, accessibilityLabel: String? = nil, accessibilityHint: String? = nil, action: @escaping () -> Void) {
        self.show = show
        self.isFavorite = isFavorite
        self.accessibilityLabel = accessibilityLabel ?? show.title
        self.accessibilityHint = accessibilityHint
        self.action = action
    }
    
    private var imageUrl: URL? {
        return url(for: show.image, size: .small)
    }
    
    private var favoriteIcon: String {
        return isFavorite ? "favorite_full" : "favorite"
    }
    
    private var numberOfEpisodes: String? {
        guard let numberOfEpisodes = show.numberOfEpisodes,
              let numberOfEpisodesString = Self.numberOfEpisodesFormatter.string(from: numberOfEpisodes) else { return nil }
        return String(format: NSLocalizedString("%@ episodes", comment: "The amount of episodes available for a show"), numberOfEpisodesString)
    }
    
    private static var numberOfEpisodesFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter
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
                    if let numberOfEpisodes {
                        Text(numberOfEpisodes)
                            .srgFont(.subtitle1)
                            .foregroundColor(.srgGrayC7)
                    }
                    Spacer()
                }
                .padding(.vertical, 2)
                .frame(maxWidth: .infinity, alignment: .leading)
                Image(decorative: favoriteIcon)
                    .padding(.trailing, 8)
            }
            .frame(height: 80)
            .onParentFocusChange { isFocused = $0 }
        }
        .buttonStyle(FlatButtonStyle(focused: isFocused, noPadding: true))
        .accessibilityElement(label: accessibilityLabel, hint: accessibilityHint, traits: .isButton)
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
