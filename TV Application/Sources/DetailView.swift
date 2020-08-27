//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

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
                    .font(.title)
                    .foregroundColor(.white)
                    .padding()
                
                if let summary = media.play_fullSummary {
                    Text(summary)
                        .foregroundColor(.white)
                        .padding()
                }
                
                HStack {
                    Button(action: {
                        // TODO: Could / should be presented with SwiftUI, but presentation flag must be part of topmost state
                        if let rootViewController = UIApplication.shared.windows.first?.rootViewController {
                            let letterboxViewController = SRGLetterboxViewController()
                            letterboxViewController.controller.playMedia(media, at: nil, withPreferredSettings: nil)
                            rootViewController.present(letterboxViewController, animated: true, completion: nil)
                        }
                    }) {
                        Image(systemName: "play.fill")
                    }
                    Button(action: { /* Toggle Watch Later state */ }) {
                        Image(systemName: "clock")
                    }
                }
                .padding()
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .edgesIgnoringSafeArea(.all)
        .redacted(reason: redactionReason)
    }
}
