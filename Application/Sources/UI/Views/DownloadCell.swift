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
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    private var direction: StackDirection {
        if layout == .horizontal || (layout == .adaptive && horizontalSizeClass == .compact) {
            return .horizontal
        }
        else {
            return .vertical
        }
    }
    
    private var horizontalPadding: CGFloat {
        return direction == .vertical ? 0 : constant(iOS: 10, tvOS: 20)
    }
    
    private var verticalPadding: CGFloat {
        return direction == .vertical ? constant(iOS: 5, tvOS: 15) : 0
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
                    MediaVisualView(media: media, size: .small)
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
            
            DescriptionView(model: model)
                .selectionAppearance(.transluscent, when: hasSelectionAppearance, while: isEditing)
                .padding(.horizontal, horizontalPadding)
                .padding(.top, verticalPadding)
        }
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
        
        private var title: String {
            return model.title ?? .placeholder(length: 10)
        }
        
        var body: some View {
            VStack(alignment: .leading) {
                Text(title)
                    .srgFont(.H4)
                    .lineLimit(2)
                    .foregroundColor(.srgGray96)
                if let subtitle = model.subtitle {
                    Text(subtitle)
                        .srgFont(.subtitle1)
                        .lineLimit(1)
                        .foregroundColor(.srgGrayC7)
                        .layoutPriority(1)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }
}

// MARK: Size

final class DownloadCellSize: NSObject {
    fileprivate static let aspectRatio: CGFloat = 16 / 9
}

// MARK: Preview

struct DownloadCell_Previews: PreviewProvider {
    // TODO: We should be able to mock downloads
    static var previews: some View {
        DownloadCell(download: nil, layout: .vertical)
        DownloadCell(download: nil, layout: .horizontal)
    }
}
