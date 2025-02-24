//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import NukeUI
import SRGAppearanceSwift
import SwiftUI

// MARK: View

struct ShowCell: View, PrimaryColorSettable {
    enum Style {
        case standard
        case favorite
    }

    @Binding private(set) var show: SRGShow?

    let style: Style
    let imageVariant: SRGImageVariant
    let isSwimlaneLayout: Bool

    var primaryColor: Color = .srgGrayD2

    @StateObject private var model = ShowCellViewModel()

    @Environment(\.isEditing) private var isEditing
    @Environment(\.isSelected) private var isSelected

    init(show: SRGShow?, style: Style, imageVariant: SRGImageVariant, isSwimlaneLayout: Bool) {
        _show = .constant(show)
        self.style = style
        self.imageVariant = imageVariant
        self.isSwimlaneLayout = isSwimlaneLayout
    }

    var body: some View {
        Group {
            #if os(tvOS)
                LabeledCardButton(aspectRatio: ShowCellSize.aspectRatio(for: imageVariant, isSwimlane: isSwimlaneLayout), action: action) {
                    ShowVisualView(show: model.show, size: .small, imageVariant: imageVariant)
                        .unredactable()
                        .accessibilityElement(label: accessibilityLabel, hint: accessibilityHint, traits: .isButton)
                } label: {
                    if imageVariant != .poster {
                        DescriptionView(model: model, style: style)
                            .primaryColor(primaryColor)
                            .frame(maxHeight: .infinity, alignment: .top)
                            .padding(.top, ShowCellSize.verticalPadding)
                    }
                }
            #else
                VStack(spacing: 0) {
                    ShowVisualView(show: model.show, size: .small, imageVariant: imageVariant, aspectRatio: ShowCellSize.aspectRatio(for: imageVariant, isSwimlane: isSwimlaneLayout))
                        .aspectRatio(ShowCellSize.aspectRatio(for: imageVariant, isSwimlane: isSwimlaneLayout), contentMode: .fit)
                    if imageVariant == .default || imageVariant == .podcast {
                        DescriptionView(model: model, style: style)
                            .primaryColor(primaryColor)
                            .padding(.horizontal, ShowCellSize.horizontalPadding)
                            .padding(.vertical, ShowCellSize.verticalPadding)
                    }
                }
                .background(Color.srgGray23)
                .redactable()
                .selectionAppearance(when: isSelected && show != nil, while: isEditing)
                .cornerRadius(LayoutStandardViewCornerRadius)
                .accessibilityElement(label: accessibilityLabel, hint: accessibilityHint, traits: accessibilityTraits)
                .frame(maxHeight: .infinity, alignment: .top)
            #endif
        }
        .redactedIfNil(show)
        .onAppear {
            model.show = show
        }
        .onChange(of: show) { newValue in
            model.show = newValue
        }
    }

    #if os(tvOS)
        private func action() {
            if let show {
                navigateToShow(show)
            }
        }
    #endif

    /// Behavior: h-exp, v-hug
    private struct DescriptionView: View, PrimaryColorSettable {
        @ObservedObject var model: ShowCellViewModel
        let style: Style

        var primaryColor: Color = .srgGrayD2

        var body: some View {
            HStack {
                Text(model.title ?? "")
                    .srgFont(.H4)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                #if os(iOS)
                    if style == .favorite, model.isSubscribed {
                        Image(.subscriptionFull)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 12)
                    }
                #endif
            }
            .foregroundColor(primaryColor)
        }
    }
}

// MARK: Accessibility

private extension ShowCell {
    var accessibilityLabel: String? {
        model.title
    }

    var accessibilityHint: String? {
        !isEditing ? PlaySRGAccessibilityLocalizedString("Opens show details.", comment: "Show cell hint") : PlaySRGAccessibilityLocalizedString("Toggles selection.", comment: "Show cell hint in edit mode")
    }

    var accessibilityTraits: AccessibilityTraits {
        isSelected ? .isSelected : []
    }
}

// MARK: Size

enum ShowCellSize {
    fileprivate static let horizontalPadding: CGFloat = constant(iOS: 10, tvOS: 0)
    fileprivate static let verticalPadding: CGFloat = constant(iOS: 5, tvOS: 7)

    private static func heightOffset(for imageVariant: SRGImageVariant) -> CGFloat {
        imageVariant == .default || imageVariant == .podcast ? constant(iOS: 32, tvOS: 45) : 0
    }

    fileprivate static func aspectRatio(for imageVariant: SRGImageVariant, isSwimlane: Bool) -> CGFloat {
        switch imageVariant {
        case .poster:
            2 / 3
        case .podcast:
            isSwimlane && ApplicationConfiguration.shared.arePodcastImagesEnabled ? 1 : 16 / 9
        case .default:
            16 / 9
        }
    }

    fileprivate static func itemWidth(for imageVariant: SRGImageVariant, isSwimlane: Bool) -> CGFloat {
        switch imageVariant {
        case .default:
            constant(iOS: 210, tvOS: 375)
        case .poster:
            constant(iOS: 158, tvOS: 276)
        case .podcast:
            if isSwimlane, ApplicationConfiguration.shared.arePodcastImagesEnabled {
                constant(iOS: 148, tvOS: 258)
            } else {
                constant(iOS: 210, tvOS: 375)
            }
        }
    }

    static func swimlane(for imageVariant: SRGImageVariant) -> NSCollectionLayoutSize {
        LayoutSwimlaneCellSize(itemWidth(for: imageVariant, isSwimlane: true), aspectRatio(for: imageVariant, isSwimlane: true), heightOffset(for: imageVariant))
    }

    static func grid(for imageVariant: SRGImageVariant, layoutWidth: CGFloat, spacing: CGFloat) -> NSCollectionLayoutSize {
        LayoutGridCellSize(itemWidth(for: imageVariant, isSwimlane: false), aspectRatio(for: imageVariant, isSwimlane: false), heightOffset(for: imageVariant), layoutWidth, spacing, 2)
    }
}

// MARK: Preview

struct ShowCell_Previews: PreviewProvider {
    private static let defaultSize = ShowCellSize.swimlane(for: .default).previewSize
    private static let posterSize = ShowCellSize.swimlane(for: .poster).previewSize
    private static let podcastSize = ShowCellSize.swimlane(for: .podcast).previewSize

    static var previews: some View {
        ShowCell(show: Mock.show(.standard), style: .standard, imageVariant: .default, isSwimlaneLayout: true)
            .previewLayout(.fixed(width: defaultSize.width, height: defaultSize.height))
        ShowCell(show: Mock.show(.standard), style: .standard, imageVariant: .poster, isSwimlaneLayout: true)
            .previewLayout(.fixed(width: posterSize.width, height: posterSize.height))
        ShowCell(show: Mock.show(.standard), style: .standard, imageVariant: .podcast, isSwimlaneLayout: false)
            .previewLayout(.fixed(width: podcastSize.width, height: podcastSize.height))
    }
}
