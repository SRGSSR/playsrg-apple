//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

struct LiveView: View {
    @StateObject var model = HomeModel(id: .live)
    
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

struct LivestreamsView_Previews: PreviewProvider {
    static var previews: some View {
        LiveView()
    }
}
