//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

struct ShowCell: View {
    enum Layout {
        case vertical
        case horizontal
    }
    
    let show: SRGShow?
    let layout: Layout
    
    init(show: SRGShow?, layout: Layout = .vertical) {
        self.show = show
        self.layout = layout
    }
    
    private var imageUrl: URL? {
        return show?.imageURL(for: .width, withValue: SizeForImageScale(.small).width, type: .default)
    }
    
    private var redactionReason: RedactionReasons {
        return show == nil ? .placeholder : .init()
    }
    
    private var accessibilityLabel: String {
        return show?.title ?? ""
    }
    
    #if os(tvOS)
    private func action() {
        if let show = show {
            navigateToShow(show)
        }
    }
    #endif
    
    var body: some View {
        GeometryReader { geometry in
            #if os(tvOS)
            LabeledCardButton(action: action) {
                ImageView(url: imageUrl)
                    .aspectRatio(contentMode: .fill)
                    .accessibilityElement()
                    .accessibilityLabel(accessibilityLabel)
                    .accessibility(addTraits: .isButton)
            } label: {
                DescriptionView(show: show)
            }
            #else
            Group {
                if layout == .horizontal {
                    HStack {
                        ImageView(url: imageUrl)
                            .aspectRatio(contentMode: .fill)
                        DescriptionView(show: show)
                            .padding(.bottom, 5)
                            .padding(.horizontal, 8)
                    }
                }
                else {
                    VStack {
                        ImageView(url: imageUrl)
                            .aspectRatio(contentMode: .fill)
                        DescriptionView(show: show)
                            .padding(.bottom, 5)
                            .padding(.horizontal, 8)
                    }
                }
            }
            .background(Color(.play_cardGrayBackground))
            .cornerRadius(LayoutStandardViewCornerRadius)
            .accessibilityElement()
            .accessibilityLabel(accessibilityLabel)
            #endif
        }
        .redacted(reason: redactionReason)
    }
    
    private struct DescriptionView: View {
        let show: SRGShow?
        
        private var title: String {
            guard let show = show else { return String(repeating: " ", count: .random(in: 10..<20)) }
            return show.title
        }
        
        var body: some View {
            Text(title)
                .srgFont(.subtitle)
                .frame(maxWidth: .infinity, alignment: .topLeading)
        }
    }
}

struct ShowCell_Previews: PreviewProvider {
    static var showPreview: SRGShow {
        let asset = NSDataAsset(name: "show-srf-tv")!
        let jsonData = try! JSONSerialization.jsonObject(with: asset.data, options: []) as? [String: Any]
        
        return try! MTLJSONAdapter(modelClass: SRGShow.self)?.model(fromJSONDictionary: jsonData) as! SRGShow
    }
    
    static var previews: some View {
        Group {
            ShowCell(show: showPreview)
                .previewLayout(.fixed(width: 375, height: 211))
                .previewDisplayName("SRF show")
        }
    }
}
