//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGDataProviderModel
import SwiftUI

struct ShowCell: View {
    private struct VisualView: View {
        let show: SRGShow?
        
        @Environment(\.isFocused) private var isFocused: Bool
        
        private var imageUrl: URL? {
            return show?.imageURL(for: .width, withValue: SizeForImageScale(.small).width, type: .default)
        }
        
        var body: some View {
            ImageView(url: imageUrl)
                .preference(key: FocusedKey.self, value: isFocused)
                .whenRedacted { $0.hidden() }
        }
    }
    
    let show: SRGShow?
    
    @State private var isFocused = false
    
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
                Button(action: {}) {
                    VisualView(show: show)
                        .frame(width: geometry.size.width, height: geometry.size.width * 9 /  16)
                }
                .buttonStyle(CardButtonStyle())
                
                Text(title)
                    .srgFont(.regular, size: .subtitle)
                    .frame(width: geometry.size.width, alignment: .leading)
                    .scaleEffect(isFocused ? 1.1 : 1)
                    .offset(x: 0, y: isFocused ? 10 : 0)
            }
            .onPreferenceChange(FocusedKey.self) { value in
                withAnimation(.easeInOut(duration: 0.2)) {
                    isFocused = value
                }
            }
            .redacted(reason: redactionReason)
        }
    }
}
