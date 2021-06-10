//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

// MARK: View

struct LiveMediaCell: View {
    @Binding private(set) var media: SRGMedia?
    @StateObject private var model = LiveMediaModel()
    
    init(media: SRGMedia?) {
        _media = .constant(media)
    }
    
    var body: some View {
        Group {
            #if os(tvOS)
            ExpandingCardButton(action: action) {
                VisualView(model: model)
                    .aspectRatio(LiveMediaCellSize.aspectRatio, contentMode: .fit)
                    .unredactable()
                    .accessibilityElement(label: accessibilityLabel, hint: accessibilityHint, traits: .isButton)
            }
            #else
            VisualView(model: model)
                .aspectRatio(LiveMediaCellSize.aspectRatio, contentMode: .fit)
                .background(Color.white.opacity(0.1))
                .redactable()
                .cornerRadius(LayoutStandardViewCornerRadius)
                .accessibilityElement(label: accessibilityLabel, hint: accessibilityHint)
            #endif
        }
        .redactedIfNil(media)
        .onAppear {
            model.media = media
        }
        .onChange(of: media) { newValue in
            model.media = newValue
        }
    }
    
    #if os(tvOS)
    private func action() {
        if let media = media {
            navigateToMedia(media, play: true)
        }
    }
    #endif
    
    /// Behavior: h-exp, v-exp
    private struct VisualView: View {
        @ObservedObject var model: LiveMediaModel
        
        var body: some View {
            ZStack {
                ImageView(url: model.imageUrl)
                Color.srgGray1.opacity(0.7)
                DescriptionView(model: model)
                BlockingOverlay(media: model.media)
                
                if let progress = model.progress {
                    ProgressBar(value: progress)
                        .opacity(progress != 0 ? 1 : 0)
                        .frame(height: LayoutProgressBarHeight)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                }
            }
        }
    }
    
    /// Behavior: h-exp, v-exp
    private struct DescriptionView: View {
        @ObservedObject var model: LiveMediaModel
        
        #if os(iOS)
        @Environment(\.horizontalSizeClass) var horizontalSizeClass
        #endif
        
        private var padding: CGFloat {
            #if os(iOS)
            if horizontalSizeClass == .compact {
                return 8
            }
            #endif
            return constant(iOS: 10, tvOS: 16)
        }
        
        var body: some View {
            VStack(alignment: .leading, spacing: 0) {
                if let logoImage = model.logoImage {
                    Image(uiImage: logoImage)
                        .padding(.bottom, 4)
                }
                
                Text(model.title)
                    .srgFont(.body, maximumSize: constant(iOS: 18, tvOS: CGFloat.infinity))
                    .lineLimit(1)
                    .foregroundColor(.white)
                
                if let subtitle = model.subtitle {
                    Text(subtitle)
                        .srgFont(.caption, maximumSize: constant(iOS: 15, tvOS: CGFloat.infinity))
                        .lineLimit(1)
                        .foregroundColor(.white)
                        .layoutPriority(1)
                }
            }
            .padding([.horizontal, .vertical], padding)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }
}

// MARK: Accessibility

private extension LiveMediaCell {
    var accessibilityLabel: String? {
        return model.accessibilityLabel
    }
    
    var accessibilityHint: String? {
        return PlaySRGAccessibilityLocalizedString("Plays the content.", "Media cell hint")
    }
}

// MARK: Size

class LiveMediaCellSize: NSObject {
    fileprivate static let aspectRatio: CGFloat = 16 / 9
    
    private static let defaultItemWidth: CGFloat = constant(iOS: 210, tvOS: 375)
    
    @objc static func swimlane() -> NSCollectionLayoutSize {
        return swimlane(itemWidth: defaultItemWidth)
    }
    
    @objc static func swimlane(itemWidth: CGFloat) -> NSCollectionLayoutSize {
        return LayoutSwimlaneCellSize(itemWidth, aspectRatio, 0)
    }
    
    @objc static func grid(layoutWidth: CGFloat, spacing: CGFloat, minimumNumberOfColumns: Int) -> NSCollectionLayoutSize {
        return grid(approximateItemWidth: defaultItemWidth, layoutWidth: layoutWidth, spacing: spacing, minimumNumberOfColumns: minimumNumberOfColumns)
    }
    
    @objc static func grid(approximateItemWidth: CGFloat, layoutWidth: CGFloat, spacing: CGFloat, minimumNumberOfColumns: Int) -> NSCollectionLayoutSize {
        return LayoutGridCellSize(approximateItemWidth, aspectRatio, 0, layoutWidth, spacing, minimumNumberOfColumns)
    }
}

// MARK: Preview

struct LiveMediaCell_Previews: PreviewProvider {
    static private let media = Mock.media(.livestream)
    static private let size = LiveMediaCellSize.swimlane().previewSize
    
    static var previews: some View {
        #if os(tvOS)
        LiveMediaCell(media: media)
            .previewLayout(.fixed(width: size.width, height: size.height))
        #else
        Group {
            LiveMediaCell(media: media)
                .previewLayout(.fixed(width: size.width, height: size.height))
                .environment(\.horizontalSizeClass, .compact)
            LiveMediaCell(media: media)
                .previewLayout(.fixed(width: size.width, height: size.height))
                .environment(\.horizontalSizeClass, .regular)
        }
        #endif
    }
}
