//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGDataProviderModel
import SwiftUI

struct HomeSwimlane: View {
    @ObservedObject var row: HomeRow
    
    var body: some View {
        ScrollView(.horizontal) {
            HStack {
                ForEach(row.medias, id: \.uid) { media in
                    MediaCell(media: media)
                }
            }
            .padding([.leading, .trailing], VideosView.horizontalPadding)
        }
    }
}

struct HomeSwimlaneHeader: View {
    let row: HomeRow
    
    var body: some View {
        Text(row.title)
            .font(.headline)
            .padding([.leading, .trailing], VideosView.horizontalPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.blue)
    }
}

struct MediaCell: View {
    let media: SRGMedia
    
    var body: some View {
        Button(action: { /* Open the player */ }) {
            Text(media.title)
                .padding()
                .frame(width: 375, height: 210)
                .background(Color.red)
        }
        .buttonStyle(CardButtonStyle())
        .padding(.top, 20)
        .padding(.bottom, 80)
    }
}

struct VideosView: View {
    @StateObject var model = HomeModel()
    static let horizontalPadding: CGFloat = 40
    
    var body: some View {
        ScrollView {
            VStack {
                ForEach(model.rows) { row in
                    Section(header: HomeSwimlaneHeader(row: row)) {
                        HomeSwimlane(row: row)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.yellow)
        }
        .onAppear {
            model.refresh()
        }
        .ignoresSafeArea(.all, edges: [.leading, .trailing, .bottom])
    }
}

struct VideosView_Previews: PreviewProvider {
    static var previews: some View {
        VideosView()
    }
}
