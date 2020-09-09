//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

struct VideosView: View {
    @StateObject var model = HomeModel(id: .video)
    
    var body: some View {
        HomeView(model: model)
            .onAppear {
                model.refresh()
            }
            .onDisappear {
                model.cancelRefresh()
            }
    }
}

