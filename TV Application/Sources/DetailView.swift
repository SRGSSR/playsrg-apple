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
                
                HStack {
                    Button(action: {
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
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }
    
    let media: SRGMedia
    
    private var imageUrl: URL? {
        return media.imageURL(for: .width, withValue: UIScreen.main.bounds.width, type: .default)
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
                    .fill(Color.gray)
                    .frame(maxWidth: .infinity, maxHeight: 305)
            }
            
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.play_black))
        .edgesIgnoringSafeArea(.all)
    }
}
