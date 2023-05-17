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
    
    @Environment(\.isSelected) var isSelected
    
    init(applicationSectioninfo: ApplicationSectionInfo?) {
        _applicationSectioninfo = .constant(applicationSectioninfo)
    }
    
    var body: some View {
        MainView(model: model)
            .selectionAppearance(.dimmed, when: isSelected)
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
        
        @Environment(\.isUIKitFocused) private var isFocused
        
        private let iconHeight: CGFloat = 24
        
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
                if !model.isModalPresentation {
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
            .previewLayout(.fixed(width: 360, height: ProfileCellSize.height()))
    }
}
