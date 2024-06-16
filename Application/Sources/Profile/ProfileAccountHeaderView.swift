//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import NukeUI
import SRGAppearanceSwift
import SwiftUI

// MARK: View

struct ProfileAccountHeaderView: View {
    @StateObject private var model = ProfileAccountHeaderViewModel()

    var body: some View {
        MainView(model: model)
    }

    /// Behavior: h-exp, v-exp
    private struct MainView: View {
        @ObservedObject var model: ProfileAccountHeaderViewModel

        @Environment(\.isUIKitFocused) private var isFocused

        private let spacing: CGFloat = LayoutMargin * 1.5
        private let iconHeight: CGFloat = 24 * 1.5
        private let lineWidth: CGFloat = 1.2

        private let serviceLogoHeight: CGFloat = 24 * 1.5 * 0.6
        private let serviceLogoOffsetX: CGFloat = 14
        private let serviceLogoOffsetY: CGFloat = -3

        private var trailingImagePadding: CGFloat {
            return UIImage(named: "identity_service_logo") != nil ? serviceLogoOffsetX : 0
        }

        var body: some View {
            Button {
                model.manageAccount()
            } label: {
                HStack(spacing: spacing) {
                    ZStack(alignment: .topTrailing) {
                        Image(model.data.icon)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: iconHeight)
                        if let emailAddress = model.data.account?.emailAddress,
                           let gravatarImageURL = URL(string: "https://www.gravatar.com/avatar/\(emailAddress.lowercased().play_md5hash)?d=404&s=\(300)") {
                            LazyImage(source: gravatarImageURL) { state in
                                if let image = state.image {
                                    image
                                        .resizingMode(.aspectFit)
                                        .frame(maxWidth: iconHeight, maxHeight: iconHeight)
                                        .mask(
                                            Circle()
                                                .frame(maxWidth: iconHeight, maxHeight: iconHeight)
                                        )
                                        .overlay(
                                            Circle()
                                                .stroke(Color.srgGrayD2, lineWidth: lineWidth)
                                                .frame(maxWidth: iconHeight - lineWidth, maxHeight: iconHeight - lineWidth)
                                        )
                                        .opacity(1)
                                } else {
                                    Rectangle()
                                        .foregroundColor(.clear)
                                        .frame(maxWidth: iconHeight, maxHeight: iconHeight)
                                }
                            }
                        }
                        if let image = UIImage(named: "identity_service_logo") {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(height: serviceLogoHeight)
                                .offset(x: serviceLogoOffsetX, y: serviceLogoOffsetY)
                        }
                    }
                    .padding(.trailing, trailingImagePadding)
                    Text(model.data.text)
                        .srgFont(.body)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Image(.chevron)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 16)
                }
                .foregroundColor(.srgGrayD2)
                .padding(.horizontal, 16)
                .padding(.vertical, 4)
                .frame(maxHeight: .infinity)
                .background(!isFocused ? Color.srgGray23 : Color.srgGray33)
                .cornerRadius(4)
                .accessibilityElement(label: model.accessibilityLabel, hint: model.accessibilityHint)
            }
        }
    }
}

// MARK: Size

extension ProfileAccountHeaderView {
    static func size() -> CGSize {
        return CGSize(width: .zero, height: 66)
    }
}

// MARK: Preview

struct ProfileAccountHeaderView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileAccountHeaderView()
            .previewLayout(.sizeThatFits)
    }
}
