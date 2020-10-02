//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGAppearance
import SRGDataProviderModel
import SRGLetterbox
import SwiftUI

struct DetailView: View {
    let media: SRGMedia
    
    @State private var isPresented = false
    
    private var imageUrl: URL? {
        return media.imageURL(for: .width, withValue: UIScreen.main.bounds.width, type: .default)
    }
    
    private var redactionReason: RedactionReasons {
        return .init()
    }
    
    var body: some View {
        ZStack {
            ImageView(url: imageUrl)
                .whenRedacted { $0.hidden() }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .redacted(reason: redactionReason)
            Rectangle()
                .fill(Color(white: 0, opacity: 0.4))
            VStack(alignment: .leading) {
                Text(media.title)
                    .srgFont(.bold, size: .title)
                    .foregroundColor(.white)
                    .padding([.top, .bottom], 5)
                
                if let show = media.show {
                    Text(show.title)
                        .srgFont(.regular, size: .headline)
                        .foregroundColor(.white)
                        .padding([.top, .bottom], 5)
                }
                
                if let summary = media.play_fullSummary {
                    Text(summary)
                        .srgFont(.light, size: .subtitle)
                        .foregroundColor(.white)
                        .padding([.top, .bottom], 5)
                }
                
                Spacer()
                    .frame(height: 90)
                
                HStack {
                    Button(action: {
                        // TODO: Could / should be presented with SwiftUI, but presentation flag must be part of topmost state
                        if let presentedViewController = UIApplication.shared.windows.first?.rootViewController?.presentedViewController {
                            let letterboxViewController = SRGLetterboxViewController()
                            letterboxViewController.controller.playMedia(media, at: nil, withPreferredSettings: nil)
                            presentedViewController.present(letterboxViewController, animated: true, completion: nil)
                        }
                    }) {
                        Image(systemName: "play.fill")
                    }
                    Button(action: { /* Toggle Watch Later state */ }) {
                        Image(systemName: "clock")
                    }
                    }
                }
                .padding([.top, .bottom], 5)
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .edgesIgnoringSafeArea(.all)
        .redacted(reason: redactionReason)
    }
}
