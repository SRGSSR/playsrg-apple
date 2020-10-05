//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGAppearance
import SRGDataProviderModel
import SRGLetterbox
import SwiftUI

struct MediaDetailView: View {
    private struct DescriptionView: View {
        let media: SRGMedia
        
        var body: some View {
            GeometryReader { geometry in
                VStack(alignment: .leading, spacing: 0) {
                    Text(MediaDescription.subtitle(for: media))
                        .srgFont(.bold, size: .title)
                        .lineLimit(3)
                        .foregroundColor(.white)
                        .padding([.top, .bottom], 5)
                    Text(MediaDescription.title(for: media))
                        .srgFont(.regular, size: .headline)
                        .foregroundColor(.white)
                        .padding([.top, .bottom], 5)
                    
                    HStack(spacing: 4) {
                        if let youthProtectionLogoImage = YouthProtectionImageForColor(media.youthProtectionColor) {
                            Image(uiImage: youthProtectionLogoImage)
                        }
                        DurationLabel(media: media)
                    }
                    
                    if let summary = media.play_fullSummary {
                        Text(summary)
                            .srgFont(.light, size: .subtitle)
                            .foregroundColor(.white)
                            .padding([.top, .bottom], 5)
                    }
                    
                    Spacer()
                    
                    HStack {
                        LabeledButton(icon: "play.fill", label: NSLocalizedString("Play", comment: "Play button label")) {
                            if let presentedViewController = UIApplication.shared.windows.first?.rootViewController?.presentedViewController {
                                let letterboxViewController = SRGLetterboxViewController()
                                letterboxViewController.controller.playMedia(media, at: nil, withPreferredSettings: nil)
                                presentedViewController.present(letterboxViewController, animated: true, completion: nil)
                            }
                        }
                        LabeledButton(icon: "clock", label: NSLocalizedString("Watch later", comment: "Watch later button label")) {
                            /* Toggle Watch Later state */
                        }
                    }
                }
                .frame(maxWidth: geometry.size.width / 2, maxHeight: .infinity, alignment: .topLeading)
            }
        }
    }
    
    let media: SRGMedia
    
    private var imageUrl: URL? {
        return media.imageURL(for: .width, withValue: SizeForImageScale(.large).width, type: .default)
    }
    
    var body: some View {
        ZStack {
            ImageView(url: imageUrl)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            Rectangle()
                .fill(Color(white: 0, opacity: 0.6))
            VStack {
                DescriptionView(media: media)
                    .padding([.top, .leading, .trailing], 100)
                    .padding(.bottom, 30)
                Rectangle()
                    .fill(Color(.srg_color(fromHexadecimalString: "#222222")!))
                    .opacity(0.8)
                    .frame(maxWidth: .infinity, maxHeight: 305)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.play_black))
        .edgesIgnoringSafeArea(.all)
    }
}
