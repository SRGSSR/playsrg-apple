//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

struct FeaturesView: View {
    var body: some View {
        Text("Features")
            .navigationTitle(NSLocalizedString("Features", comment: "Title displayed at the top of the Features view"))
    }
}

struct FeaturesView_Previews: PreviewProvider {
    static var previews: some View {
        FeaturesView()
    }
}
