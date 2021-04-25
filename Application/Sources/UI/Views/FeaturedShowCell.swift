//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGAppearanceSwift
import SwiftUI

struct FeaturedShowCell: View {
    enum Layout {
        case hero
        case highlight
    }
    
    let show: SRGShow?
    let layout: Layout
    
    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    #endif
    
    private var redactionReason: RedactionReasons {
        return show == nil ? .placeholder : .init()
    }
    
    private var imageUrl: URL? {
        return show?.imageURL(for: .width, withValue: SizeForImageScale(.large).width, type: .default)
    }
    
    var body: some View {
        GeometryReader { geometry in
            #if os(tvOS)
            Button(action: {
                if let show = show {
                    navigateToShow(show)
                }
            }) {
                HStack(spacing: 0) {
                    ImageView(url: imageUrl)
                        .frame(width: geometry.size.height * 16 / 9, height: geometry.size.height)
                    DescriptionView(show: show, layout: layout)
                        .padding()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
                .background(Color(.srg_color(fromHexadecimalString: "#232323")!))
                .cornerRadius(LayoutStandardViewCornerRadius)
                .redacted(reason: redactionReason)
                .accessibilityElement()
                .accessibilityLabel(show?.title ?? "")
                .accessibility(addTraits: .isButton)
            }
            .buttonStyle(CardButtonStyle())
            #else
            if horizontalSizeClass == .compact {
                VStack(spacing: 0) {
                    ImageView(url: imageUrl)
                        .frame(width: geometry.size.width, height: geometry.size.width * 9 /  16)
                    DescriptionView(show: show, layout: layout)
                        .padding()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
                .background(Color(.srg_color(fromHexadecimalString: "#232323")!))
                .cornerRadius(LayoutStandardViewCornerRadius)
                .redacted(reason: redactionReason)
                .accessibilityElement()
                .accessibilityLabel(show?.title ?? "")
                .accessibility(addTraits: .isButton)
            }
            else {
                HStack(spacing: 0) {
                    ImageView(url: imageUrl)
                        .frame(width: geometry.size.height * 16 / 9, height: geometry.size.height)
                    DescriptionView(show: show, layout: layout)
                        .padding()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
                .background(Color(.srg_color(fromHexadecimalString: "#232323")!))
                .cornerRadius(LayoutStandardViewCornerRadius)
                .redacted(reason: redactionReason)
                .accessibilityElement()
                .accessibilityLabel(show?.title ?? "")
                .accessibility(addTraits: .isButton)
            }
            #endif
        }
    }
    
    private struct DescriptionView: View {
        let show: SRGShow?
        let layout: Layout
        
        #if os(iOS)
        @Environment(\.horizontalSizeClass) private var horizontalSizeClass
        #endif
        
        var body: some View {
            #if os(iOS)
            if horizontalSizeClass == .compact {
                CompactDescriptionView(show: show, layout: layout)
                    .padding(0)
            }
            else {
                LargeDescriptionView(show: show, layout: layout)
                    .padding(0)
            }
            #else
            LargeDescriptionView(show: show, layout: layout)
                .padding(0)
            #endif
        }
    }
    
    private struct LargeDescriptionView: View {
        let show: SRGShow?
        let layout: Layout
        
        private func textAlignment() -> TextAlignment {
            return layout == .highlight ? .leading : .center
        }
        
        private func alignment() -> Alignment {
            return layout == .highlight ? .leading : .center
        }
        
        var body: some View {
            VStack {
                Spacer()
                Text(show?.title ?? "")
                    .srgFont(.H2)
                    .lineLimit(2)
                    .multilineTextAlignment(textAlignment())
                    .frame(maxWidth: .infinity, alignment: alignment())
                    .padding()
                if let lead = show?.lead {
                    Spacer()
                        .frame(height: LayoutFeaturedSpacerHeight * 2)
                    Text(lead)
                        .srgFont(.body)
                        .lineLimit(4)
                        .multilineTextAlignment(textAlignment())
                        .frame(maxWidth: .infinity, alignment: alignment())
                        .opacity(0.8)
                        .padding()
                }
                
                if let broadcastInformationMessage = show?.broadcastInformation?.message {
                    Badge(text: broadcastInformationMessage, color: Color(.play_gray))
                }
                Spacer()
            }
            .foregroundColor(.white)
        }
    }
    
    private struct CompactDescriptionView: View {
        let show: SRGShow?
        let layout: Layout
        
        private var title: String {
            guard let show = show else { return String(repeating: " ", count: .random(in: 10..<20)) }
            return show.title
        }
        
        var body: some View {
            VStack(alignment: .leading) {
                Text(title)
                    .srgFont(.H2)
                    .lineLimit(2)
                if let lead = show?.lead {
                    Text(lead)
                        .srgFont(.body)
                        .lineLimit(2)
                        .layoutPriority(1)
                }
            }
        }
    }
}

struct FeaturedShowCell_Previews: PreviewProvider {
    static var showPreview: SRGShow {
        let asset = NSDataAsset(name: "show-srf-tv")!
        let jsonData = try! JSONSerialization.jsonObject(with: asset.data, options: []) as? [String: Any]
        
        return try! MTLJSONAdapter(modelClass: SRGShow.self)?.model(fromJSONDictionary: jsonData) as! SRGShow
    }
    
    static var previews: some View {
        Group {
            FeaturedShowCell(show: showPreview, layout: .hero)
                .previewLayout(.fixed(width: 1740, height: 680))
                .previewDisplayName("SRF show, hero layout")
            
            FeaturedShowCell(show: showPreview, layout: .highlight)
                .previewLayout(.fixed(width: 1740, height: 480))
                .previewDisplayName("SRF show, highlighted layout")
        }
    }
}
