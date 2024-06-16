//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGAppearanceSwift
import SwiftUI

// MARK: View

struct ProfileCell: View {
    @Binding private(set) var applicationSectioninfo: ApplicationSectionInfo?

    @StateObject private var model = ProfileCellModel()

    init(applicationSectioninfo: ApplicationSectionInfo?) {
        _applicationSectioninfo = .constant(applicationSectioninfo)
    }

    var body: some View {
        MainView(model: model)
            .onAppear {
                model.applicationSectioninfo = applicationSectioninfo
            }
            .onChange(of: applicationSectioninfo) { newValue in
                model.applicationSectioninfo = newValue
            }
    }

    /// Behavior: h-exp, v-exp
    private struct MainView: View {
        @ObservedObject var model: ProfileCellModel

        @Environment(\.isSelected) private var isSelected
        @Environment(\.isUIKitFocused) private var isFocused

        private let iconHeight: CGFloat = 24

        private var accessibilityLabel: String? {
            if model.unreads {
                return "\(model.title ?? ""), \(PlaySRGAccessibilityLocalizedString("Unreads", comment: "Unreads state button"))"
            } else {
                return model.title
            }
        }

        private var accessibilityTraits: AccessibilityTraits {
            return isSelected ? [.isButton, .isSelected] : .isButton
        }

        var body: some View {
            HStack(spacing: LayoutMargin) {
                if let image = model.image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: iconHeight)
                }
                if let title = model.title {
                    Text(title)
                        .srgFont(.body)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                if model.unreads {
                    Text("●")
                        .foregroundColor(Color(.play_notificationRed))
                        .srgFont(.subtitle1)
                }
                if !model.isModalPresentation {
                    Image(.chevron)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 16)
                }
            }
            .foregroundColor(.srgGrayD2)
            .padding(.horizontal, 16)
            .padding(.vertical, 4)
            .frame(maxHeight: .infinity)
            .background(!isFocused && !isSelected ? Color.srgGray23 : Color.srgGray33)
            .cornerRadius(4)
            .accessibilityElement(label: accessibilityLabel, traits: accessibilityTraits)
        }
    }
}

// MARK: Size

class ProfileCellSize: NSObject {
    @objc static func height() -> CGFloat {
        return 50
    }
}

// MARK: Preview

struct ProfileCell_Previews: PreviewProvider {
    static var previews: some View {
        ProfileCell(applicationSectioninfo: ApplicationSectionInfo(applicationSection: .favorites, radioChannel: nil))
            .previewLayout(.fixed(width: 360, height: ProfileCellSize.height()))
        ProfileCell(applicationSectioninfo: ApplicationSectionInfo(applicationSection: .favorites, radioChannel: nil))
            .previewLayout(.fixed(width: 360, height: ProfileCellSize.height()))
            .environment(\.isSelected, true)
    }
}
