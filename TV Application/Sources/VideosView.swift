//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGDataProviderModel
import SwiftUI

struct VideosView: View {
    @StateObject var model = HomeModel(rowIds: ApplicationConfiguration.shared.videoHomeRowIds())
    
    var body: some View {
        HomeView(model: model)
    }
}

struct VideosView_Previews: PreviewProvider {
    static var previews: some View {
        VideosView()
    }
}
