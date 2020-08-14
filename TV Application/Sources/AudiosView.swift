//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

struct AudiosView: View {
    @StateObject var model = HomeModel(rowIds: ApplicationConfiguration.radioHomeRowIds(for: "a9e7621504c6959e35c3ecbe7f6bed0446cdf8da"))
    
    var body: some View {
        HomeView(model: model)
    }
}

struct AudiosView_Previews: PreviewProvider {
    static var previews: some View {
        AudiosView()
    }
}
