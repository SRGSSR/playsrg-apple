//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGDataProviderModel
import SwiftUI

// MARK: View

struct SearchSettingsView: View {
    @ObservedObject var model: SearchViewModel
    
    var body: some View {
        Text("Settings")
            .navigationTitle(NSLocalizedString("Filters", comment: "Search filters page title"))
    }
}

// MARK: Preview

struct SearchSettingsPreviews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SearchSettingsView(model: SearchViewModel())
        }
        .navigationViewStyle(.stack)
    }
}
