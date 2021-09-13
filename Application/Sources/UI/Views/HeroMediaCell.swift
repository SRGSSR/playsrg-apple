//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

// MARK: View

struct HeroMediaCell: View {
    let media: SRGMedia?
    let label: String?
    
    @Environment(\.isSelected) private var isSelected
    
    var body: some View {
        #if os(tvOS)
        ExpandingCardButton(action: action) {
            MainView(media: media, label: label)
                .accessibilityElement(label: accessibilityLabel, hint: accessibilityHint, traits: .isButton)
        }
        #else
        MainView(media: media, label: label)
            .background(Color.white.opacity(0.1))
            .cornerRadius(LayoutStandardViewCornerRadius)
            .selectionAppearance(when: isSelected)
            .accessibilityElement(label: accessibilityLabel, hint: accessibilityHint)
        #endif
    }
    
    #if os(tvOS)
    private func action() {
        if let media = media {
            navigateToMedia(media)
        }
    }
    #endif
    
    private struct MainView: View {
        let media: SRGMedia?
        let label: String?
        
        var body: some View {
            ZStack {
                MediaVisualView(media: media, scale: .large, contentMode: .fill) { media in
                    if media != nil {
                        #if os(iOS)
                        LinearGradient(gradient: Gradient(colors: [.clear, .init(white: 0, opacity: 0.6)]), startPoint: .center, endPoint: .top)
                        #endif
                        LinearGradient(gradient: Gradient(colors: [.clear, .init(white: 0, opacity: 0.6)]), startPoint: .center, endPoint: .bottom)
                    }
                }
                DescriptionView(media: media, label: label)
                    .frame(maxWidth: constant(iOS: 600, tvOS: 1200))
            }
        }
    }
    
    /// Behavior: h-exp, v-exp
    private struct DescriptionView: View {
        let media: SRGMedia?
        let label: String?
        
        private var subtitle: String? {
            guard let media = media else { return nil }
            return MediaDescription.subtitle(for: media, style: .show)
        }
        
        private var title: String? {
            guard let media = media else { return nil }
            return MediaDescription.title(for: media, style: .show)
        }
        
        var body: some View {
            VStack {
                HStack(spacing: constant(iOS: 8, tvOS: 12)) {
                    if let label = label {
                        Badge(text: label, color: Color(.play_green))
                    }
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .srgFont(.subtitle1)
                            .lineLimit(1)
                    }
                }
                if let title = title {
                    Text(title)
                        .srgFont(.H2)
                        .lineLimit(2)
                }
            }
            .multilineTextAlignment(.center)
            .foregroundColor(.white)
            .padding(.bottom, constant(iOS: 30, tvOS: 60))
            .padding(.horizontal, constant(iOS: 18, tvOS: 30))
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        }
    }
}

// MARK: Accessibility

private extension HeroMediaCell {
    var accessibilityLabel: String? {
        guard let media = media else { return nil }
        return MediaDescription.accessibilityLabel(for: media)
    }
    
    var accessibilityHint: String? {
        return PlaySRGAccessibilityLocalizedString("Plays the content.", comment: "Media cell hint")
    }
}

// MARK: Size

final class HeroMediaCellSize: NSObject {
    @objc static func recommended(layoutWidth: CGFloat, horizontalSizeClass: UIUserInterfaceSizeClass) -> NSCollectionLayoutSize {
        let height = (horizontalSizeClass == .compact) ? min(layoutWidth * 9 / 11, 400) : min(layoutWidth * 9 / 16, constant(iOS: 550, tvOS: 700))
        return NSCollectionLayoutSize(widthDimension: .absolute(layoutWidth), heightDimension: .absolute(height))
    }
}

// MARK: Preview

private extension View {
    func previewLayout(for layoutWidth: CGFloat, horizontalSizeClass: UIUserInterfaceSizeClass) -> some View {
        let size = HeroMediaCellSize.recommended(layoutWidth: layoutWidth, horizontalSizeClass: horizontalSizeClass).previewSize
        return previewLayout(.fixed(width: size.width, height: size.height))
            .horizontalSizeClass(horizontalSizeClass)
    }
}

struct HeroMediaCell_Previews: PreviewProvider {
    static var previews: some View {
        #if os(tvOS)
        HeroMediaCell(media: Mock.media(), label: "New")
            .previewLayout(for: 1920, horizontalSizeClass: .regular)
        #else
        HeroMediaCell(media: Mock.media(), label: "New")
            .previewLayout(for: 375, horizontalSizeClass: .compact)
        HeroMediaCell(media: Mock.media(), label: "New")
            .previewLayout(for: 800, horizontalSizeClass: .regular)
        #endif
    }
}
