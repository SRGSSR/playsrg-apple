//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

struct ShowCell: View {
    let show: SRGShow?
    
    private var redactionReason: RedactionReasons {
        return show == nil ? .placeholder : .init()
    }
    
    var body: some View {
        GeometryReader { geometry in
            #if os(tvOS)
            LabeledCardButton(action: {
                if let show = show {
                    navigateToShow(show)
                }
            }) {
                VisualView(show: show)
                    .frame(width: geometry.size.width, height: geometry.size.width * 9 /  16)
            } label: {
                DescriptionView(show: show)
                    .frame(width: geometry.size.width, alignment: .leading)
            }
            #else
            VStack {
                VisualView(show: show)
                    .frame(width: geometry.size.width, height: geometry.size.width * 9 /  16)
                DescriptionView(show: show)
                    .frame(width: geometry.size.width, alignment: .leading)
            }
            #endif
        }
        .redacted(reason: redactionReason)
    }
    
    private struct VisualView: View {
        let show: SRGShow?
        
        private var imageUrl: URL? {
            return show?.imageURL(for: .width, withValue: SizeForImageScale(.small).width, type: .default)
        }
        
        var body: some View {
            ImageView(url: imageUrl)
                .accessibilityElement()
                .accessibilityLabel(show?.title ?? "")
        }
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
