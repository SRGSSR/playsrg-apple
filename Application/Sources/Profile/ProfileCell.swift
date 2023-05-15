//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGAppearanceSwift
import SwiftUI

// MARK: View

struct ProfileCell: View {
    let applicationSectioninfo: ApplicationSectionInfo
    
    @Environment(\.isSelected) var isSelected
    
    var body: some View {
        MainView(applicationSectioninfo: applicationSectioninfo)
            .selectionAppearance(.dimmed, when: isSelected)
    }
    
    /// Behavior: h-exp, v-exp
    private struct MainView: View {
        let applicationSectioninfo: ApplicationSectionInfo
        
        @Environment(\.isUIKitFocused) private var isFocused
        
        private let iconHeight: CGFloat = 24
        
        var body: some View {
            HStack(spacing: 8) {
                if let image = applicationSectioninfo.image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: iconHeight)
                }
                Text(applicationSectioninfo.title)
                    .srgFont(.body)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if !applicationSectioninfo.isModalPresentation {
                    Image(decorative: "chevron")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 16)
                }
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

class ProfileCellSize: NSObject {
    @objc static func height() -> CGFloat {
        let fontMetrics = UIFontMetrics(forTextStyle: .body)
        return fontMetrics.scaledValue(for: 50.0)
    }
}

// MARK: Preview

struct ProfileCell_Previews: PreviewProvider {
    static var previews: some View {
        ProfileCell(applicationSectioninfo: ApplicationSectionInfo(applicationSection: .favorites, radioChannel: nil))
            .previewLayout(.sizeThatFits)
    }
}
