//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

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
        
        private let layoutScale: CGFloat = 1.5
        private let iconHeight: CGFloat = 24 * 1.5
        
        private let serviceLogoHeight: CGFloat = 24 * 1.5 * 0.6
        private let serviceLogoOffsetX: CGFloat = 14
        private let serviceLogoOffsetY: CGFloat = -3
        
        var body: some View {
            Button {
                model.manageAccount()
            } label: {
                HStack(spacing: LayoutMargin * layoutScale) {
                    ZStack(alignment: .topTrailing) {
                        Image(decorative: model.data.decorativeName)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: iconHeight)
                        if let image = UIImage(named: "identity_service_logo") {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(height: serviceLogoHeight)
                                .offset(x: serviceLogoOffsetX, y: serviceLogoOffsetY)
                        }
                    }
                    .padding(.trailing, trailingImagePadding)
                    Text(model.data.accountText)
                        .srgFont(.body)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Image(decorative: "chevron")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 16)
                }
                .foregroundColor(.srgGrayC7)
                .padding(.horizontal, 16)
                .padding(.vertical, 4)
                .frame(maxHeight: .infinity)
                .background(!isFocused ? Color.srgGray23 : Color.srgGray33)
                .cornerRadius(4)
            }
        }
        
        private var trailingImagePadding: CGFloat {
            return UIImage(named: "identity_service_logo") != nil ? serviceLogoOffsetX : 0
        }
    }
}

// MARK: Size

extension ProfileAccountHeaderView {
    static func size() -> CGSize {
        let fontMetrics = UIFontMetrics(forTextStyle: .body)
        return CGSize(width: .zero, height: fontMetrics.scaledValue(for: 66.0))
    }
}

// MARK: Preview

struct ProfileAccountHeaderView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileAccountHeaderView()
            .previewLayout(.sizeThatFits)
    }
}