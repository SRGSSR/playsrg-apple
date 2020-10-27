//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGAppearance
import SwiftUI

struct ShowDetailView: View {
    let show: SRGShow
        
    init(show: SRGShow) {
        self.show = show
    }
    
    var body: some View {
        ZStack {
            VStack {
                DescriptionView(show: show)
                    .frame(maxWidth: .infinity, maxHeight: 300)
                    .padding(.zero)
                Spacer()
                // Collection or LazyVGrid
            }
            .padding(.zero)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding([.top, .leading, .trailing], 100)
        .background(Color(.play_black))
        .edgesIgnoringSafeArea(.all)
    }
}

extension ShowDetailView {
    private struct DescriptionView: View {
        let show: SRGShow
        
        private var imageUrl: URL? {
            return show.imageURL(for: .width, withValue: SizeForImageScale(.medium).width, type: .default)
        }
        
        var body: some View {
            GeometryReader { geometry in
                HStack {
                    ImageView(url: imageUrl)
                        .frame(maxWidth: geometry.size.width / 3, maxHeight: .infinity)
                        .padding(.zero)
                    VStack(alignment: .leading, spacing: 0) {
                        Text(show.title)
                            .srgFont(.bold, size: .title)
                            .lineLimit(3)
                            .foregroundColor(.white)
                            .padding(.zero)
                        if let lead = show.lead {
                            Text(lead)
                                .srgFont(.regular, size: .headline)
                                .foregroundColor(.white)
                                .padding(.zero)
                        }
                        
                        Spacer()
                    }
                    .frame(alignment: .topLeading)
                    ActionsView(show: show)
                }
            }
        }
    }
}

extension ShowDetailView {
    private struct ActionsView: View {
        let show: SRGShow
        
        var body: some View {
            VStack(alignment: .trailing) {
                LabeledButton(icon: "favorite-22", label: NSLocalizedString("Add to favorites", comment:"Add to favorites button label")) {
                    /* Toggle Favorite state */
                }
                Spacer()
            }
            .frame(width: 200)
            .padding(.zero)
        }
    }
}

