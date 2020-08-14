//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGDataProviderModel
import SwiftUI

struct VideosView: View {
    @StateObject var model = HomeModel()
    static let horizontalPadding: CGFloat = 40
    
    var body: some View {
        ScrollView {
            VStack {
                ForEach(model.rows) { row in
                    HomeSwimlane(row: row)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
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
