//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

struct ShowCell: View {
    let show: SRGShow?
    let action: (() -> Void)?
    
    fileprivate var onFocusAction: ((Bool) -> Void)? = nil
    
    @State private var isFocused: Bool = false
    
    init(show: SRGShow?, action: (() -> Void)? = nil) {
        self.show = show
        self.action = action
    }
    
    private var title: String {
        guard let show = show else { return String(repeating: " ", count: .random(in: 10..<20)) }
        return show.title
    }
    
    private var redactionReason: RedactionReasons {
        return show == nil ? .placeholder : .init()
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                Button(action: action ?? {
                    if let show = show {
                        navigateToShow(show)
                    }
                }) {
                    VisualView(show: show)
                        .frame(width: geometry.size.width, height: geometry.size.width * 9 /  16)
                        .onFocusChange { focused in
                            isFocused = focused
                            
                            if let onFocusAction = self.onFocusAction {
                                onFocusAction(focused)
                            }
                        }
                        .accessibilityElement()
                        .accessibilityLabel(show?.title ?? "")
                        .accessibility(addTraits: .isButton)
                }
                .buttonStyle(CardButtonStyle())
                
                Text(title)
                    .srgFont(.subtitle)
                    .frame(width: geometry.size.width, alignment: .leading)
                    .opacity(isFocused ? 1 : 0.5)
                    .offset(x: 0, y: isFocused ? 10 : 0)
                    .scaleEffect(isFocused ? 1.1 : 1, anchor: .top)
                    .animation(.easeInOut(duration: 0.2))
            }
            .redacted(reason: redactionReason)
        }
    }
    
    private struct VisualView: View {
        let show: SRGShow?
        
        private var imageUrl: URL? {
            return show?.imageURL(for: .width, withValue: SizeForImageScale(.small).width, type: .default)
        }
        
        var body: some View {
            ImageView(url: imageUrl)
        }
    }
}

extension ShowCell {
    func onFocus(perform action: @escaping (Bool) -> Void) -> ShowCell {
        var showCell = self
        showCell.onFocusAction = action
        return showCell
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
