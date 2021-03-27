//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGAppearance
import SwiftUI

struct HeroShowCell: View {
    let show: SRGShow?
    
    private var redactionReason: RedactionReasons {
        return show == nil ? .placeholder : .init()
    }
    
    private var imageUrl: URL? {
        return show?.imageURL(for: .width, withValue: SizeForImageScale(.large).width, type: .default)
    }
    
    var body: some View {
        GeometryReader { geometry in
            Button(action: {
                if let show = show {
                    navigateToShow(show)
                }
            }) {
                HStack(spacing: 0) {
                    ImageView(url: imageUrl)
                        .frame(width: geometry.size.height * 16 / 9, height: geometry.size.height)
                    DescriptionView(show: show)
                        .padding()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
                .background(Color(.srg_color(fromHexadecimalString: "#232323")!))
                .redacted(reason: redactionReason)
                .accessibilityElement()
                .accessibilityLabel(show?.title ?? "")
                .accessibility(addTraits: .isButton)
            }
            .buttonStyle(CardButtonStyle())
        }
    }
    
    private struct DescriptionView: View {
        let show: SRGShow?
        
        var body: some View {
            VStack {
                Spacer()
                Text(show?.title ?? "")
                    .srgFont(.title2)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .padding()
                if let lead = show?.lead {
                    Spacer()
                        .frame(height: 20)
                    Text(lead)
                        .srgFont(.body)
                        .lineLimit(4)
                        .multilineTextAlignment(.center)
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
}
