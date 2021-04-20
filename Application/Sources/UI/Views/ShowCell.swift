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
    
    var body: some View {
        GeometryReader { geometry in
            #if os(tvOS)
            LabeledCardButton(action: {
                if let show = show {
                    navigateToShow(show)
                }
            }) {
                ImageView(url: imageUrl)
                    .frame(width: geometry.size.width, height: geometry.size.width * 9 /  16)
                    .accessibilityElement()
                    .accessibilityLabel(accessibilityLabel)
                    .accessibility(addTraits: .isButton)
            } label: {
                DescriptionView(show: show)
                    .frame(width: geometry.size.width, alignment: .leading)
            }
            #else
            Group {
                if layout == .horizontal {
                    HStack {
                        ImageView(url: imageUrl)
                            .frame(width: geometry.size.height * 16 / 9, height: geometry.size.height)
                        DescriptionView(show: show)
                            .padding(.bottom, 5)
                            .padding(.horizontal, 8)
                            .frame(maxWidth: .infinity, maxHeight: geometry.size.height, alignment: .topLeading)
                    }
                }
                else {
                    VStack {
                        ImageView(url: imageUrl)
                            .frame(width: geometry.size.width, height: geometry.size.width * 9 /  16)
                        DescriptionView(show: show)
                            .padding(.bottom, 5)
                            .padding(.horizontal, 8)
                            .frame(width: geometry.size.width, alignment: .leading)
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
