//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGAppearance
import SRGLetterbox
import SwiftUI

struct HeroMediaCell: View {
    private struct DescriptionView: View {
        let media: SRGMedia?
        
        var body: some View {
            VStack {
                Spacer()
                Text(MediaDescription.title(for: media))
                    .srgFont(.regular, size: .subtitle)
                    .lineLimit(1)
                    .opacity(0.8)
                Spacer()
                    .frame(height: 20)
                Text(MediaDescription.subtitle(for: media))
                    .srgFont(.medium, size: .title)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                if let summary = MediaDescription.summary(for: media) {
                    Spacer()
                        .frame(height: 40)
                    Text(summary)
                        .srgFont(.regular, size: .subtitle)
                        .lineLimit(4)
                        .multilineTextAlignment(.center)
                        .opacity(0.8)
                }
                Spacer()
            }
            .foregroundColor(.white)
        }
    }
    
    let media: SRGMedia?
    
    private var redactionReason: RedactionReasons {
        return media == nil ? .placeholder : .init()
    }
    
    var body: some View {
        GeometryReader { geometry in
            Button(action: {
                // TODO: Could / should be presented with SwiftUI, but presentation flag must be part of topmost state
                if let media = media,
                   let rootViewController = UIApplication.shared.windows.first?.rootViewController {
                    let letterboxViewController = SRGLetterboxViewController()
                    letterboxViewController.controller.playMedia(media, at: nil, withPreferredSettings: nil)
                    rootViewController.present(letterboxViewController, animated: true, completion: nil)
                }
            }) {
                HStack(spacing: 0) {
                    MediaVisual(media: media, scale: .large)
                        .frame(width: geometry.size.height * 16 / 9, height: geometry.size.height)
                    DescriptionView(media: media)
                        .padding()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
                .background(Color(.srg_color(fromHexadecimalString: "#333333")!))
                .redacted(reason: redactionReason)
            }
            .buttonStyle(CardButtonStyle())
        }
    }
}
