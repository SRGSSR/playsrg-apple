//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

struct AudiosView: View {
    // TODO:
    @StateObject var model = HomeModel(rowIds: ApplicationConfiguration.shared.videoHomeRowIds())
    
    var body: some View {
        HomeView(model: model)
    }
}

struct AudiosView_Previews: PreviewProvider {
    static var previews: some View {
        AudiosView()
    }
}
