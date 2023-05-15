//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGAppearanceSwift
import SwiftUI

// MARK: View

struct ProfileAccountHeaderView: View {
    @Environment(\.isSelected) var isSelected
    
    var body: some View {
        MainView()
            .selectionAppearance(.dimmed, when: isSelected)
    }
    
    /// Behavior: h-exp, v-exp
    private struct MainView: View {
        @Environment(\.isUIKitFocused) private var isFocused
        
        private var spacing: CGFloat {
            return 10
        }
        
        private let iconHeight: CGFloat = 36
        
        var body: some View {
            HStack(spacing: 8) {
                Image(decorative: "account_logged_in_icon")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: iconHeight)
                Text(NSLocalizedString("My account", comment: "Text displayed when a user is logged in but no information has been retrieved yet"))
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
