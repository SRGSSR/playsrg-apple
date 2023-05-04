//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGAppearanceSwift
import SwiftUI

// MARK: Cell

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
        
        private var spacing: CGFloat {
            return 10
        }
        
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

struct ProfileCell_Previews: PreviewProvider {
    static var previews: some View {
        ProfileCell(applicationSectioninfo: ApplicationSectionInfo(applicationSection: .favorites, radioChannel: nil))
            .previewLayout(.sizeThatFits)
    }
}
