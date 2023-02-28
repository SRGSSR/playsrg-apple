//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGAppearanceSwift
import SwiftUI

// MARK: View

struct DownloadCell: View {
    enum Layout {
        case vertical
        case horizontal
        case adaptive
    }
    
    @Binding private(set) var download: Download?
    @StateObject private var model = DownloadCellViewModel()
    
    let layout: Layout
    
    @Environment(\.isEditing) private var isEditing
    @Environment(\.isSelected) private var isSelected
    @Environment(\.uiHorizontalSizeClass) private var horizontalSizeClass
    
    private var direction: StackDirection {
        if layout == .horizontal || (layout == .adaptive && horizontalSizeClass == .compact) {
            return .horizontal
        }
        else {
            return .vertical
        }
    }
    
    private var horizontalPadding: CGFloat {
        return direction == .vertical ? 0 : 10
    }
    
    private var verticalPadding: CGFloat {
        return direction == .vertical ? 5 : 0
    }
    
    private var hasSelectionAppearance: Bool {
        return isSelected && download != nil
    }
    
    private var imageUrl: URL? {
        return url(for: download?.image, size: .small)
    }
    
    init(download: Download?, layout: Layout = .adaptive) {
        _download = .constant(download)
        self.layout = layout
    }
    
    var body: some View {
        Stack(direction: direction, spacing: 0) {
            Group {
                if let media = download?.media {
                    MediaVisualView(media: media, size: .small, embeddedDirection: direction)
                }
                else {
                    ImageView(source: imageUrl)
                }
            }
            .aspectRatio(DownloadCellSize.aspectRatio, contentMode: .fit)
            .background(Color.placeholder)
            .selectionAppearance(when: hasSelectionAppearance, while: isEditing)
            .cornerRadius(LayoutStandardViewCornerRadius)
            .redactable()
            .layoutPriority(1)
            
            DescriptionView(model: model, embeddedDirection: direction)
                .selectionAppearance(.transluscent, when: hasSelectionAppearance, while: isEditing)
                .padding(.horizontal, horizontalPadding)
                .padding(.top, verticalPadding)
        }
        .accessibilityElement(label: accessibilityLabel, hint: accessibilityHint, traits: accessibilityTraits)
        .onAppear {
            model.download = download
        }
        .onChange(of: download) { newValue in
            model.download = newValue
        }
    }
    
    /// Behavior: h-exp, v-exp
    private struct DescriptionView: View {
        @ObservedObject var model: DownloadCellViewModel
        
        let embeddedDirection: StackDirection
        
        private var title: String {
            return model.title ?? .placeholder(length: 10)
        }
        
        var body: some View {
            VStack(alignment: .leading, spacing: 0) {
                if embeddedDirection == .horizontal, let properties = model.availabilityBadgeProperties {
                    Badge(text: properties.text, color: Color(properties.color))
                        .padding(.bottom, 4)
                }
                Text(title)
                    .srgFont(.H4)
                    .lineLimit(embeddedDirection == .horizontal ? 3 : 2)
                HStack {
                    Icon(model: model)
                    if let subtitle = model.subtitle {
                        Text(subtitle)
                            .srgFont(.subtitle1)
                            .lineLimit(1)
                            .foregroundColor(.srgGrayC7)
                            .layoutPriority(1)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }
    
    /// Behavior: h-hug, v-hug
    private struct Icon: View {
        @ObservedObject var model: DownloadCellViewModel
        
        var body: some View {
            switch model.state {
            case .added, .suspended, .unknown:
                Image(decorative: "downloadable_stop")
            case .downloading:
                AnimatedDownloadIcon()
            case .downloaded:
                Image(decorative: "downloadable_full")
            case .downloadable, .removed:
                Image(decorative: "downloadable")
            }
        }
    }
    
    /// Behavior: h-hug, v-hug
    private struct AnimatedDownloadIcon: View {
        var body: some View {
            DownloadImageView()
                .frame(width: 16, height: 16)
        }
        
        private struct DownloadImageView: UIViewRepresentable {
            func makeUIView(context: Context) -> UIImageView {
                return UIImageView.play_smallDownloadingImageView(withTintColor: .srgGrayC7)
            }
            
            func updateUIView(_ uiView: UIImageView, context: Context) {
                // No update logic required
            }
        }
    }
}

// MARK: Accessibility

private extension DownloadCell {
    var accessibilityLabel: String? {
        guard let download else { return nil }
        if let media = download.media {
            return MediaDescription.accessibilityLabel(for: media)
        }
        else {
            return download.title
        }
    }
    
    var accessibilityHint: String? {
        return !isEditing ? PlaySRGAccessibilityLocalizedString("Plays the content.", comment: "Download cell hint") : PlaySRGAccessibilityLocalizedString("Toggles selection.", comment: "Download cell hint in edit mode")
    }
    
    var accessibilityTraits: AccessibilityTraits {
        return isSelected ? .isSelected : []
    }
}

// MARK: Size

enum DownloadCellSize {
    fileprivate static let aspectRatio: CGFloat = 16 / 9
    
    private static let defaultItemWidth: CGFloat = 210
    private static let heightOffset: CGFloat = 70
    
    static func grid(layoutWidth: CGFloat, spacing: CGFloat) -> NSCollectionLayoutSize {
        return LayoutGridCellSize(defaultItemWidth, aspectRatio, heightOffset, layoutWidth, spacing, 1)
    }
    
    static func fullWidth() -> NSCollectionLayoutSize {
        return NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(84))
    }
}
