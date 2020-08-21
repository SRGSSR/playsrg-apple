//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

struct LiveView: View {
    @StateObject var model = HomeModel(rowIds: ApplicationConfiguration.shared.liveHomeRowIds())
    
    var body: some View {
        HomeView(model: model)
    }
}

struct LivestreamsView_Previews: PreviewProvider {
    static var previews: some View {
        LiveView()
    }
}
