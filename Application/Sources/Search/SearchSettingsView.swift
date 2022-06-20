//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGDataProviderModel
import SwiftUI

// MARK: View

struct SearchSettingsView: View {
    let query: String?
    let settings: SRGMediaSearchSettings
    
    var body: some View {
        Text("Settings")
            .navigationTitle(NSLocalizedString("Filters", comment: "Search filters page title"))
    }
}

// MARK: Preview

struct SearchSettingsPreviews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SearchSettingsView(query: nil, settings: SRGMediaSearchSettings())
        }
        .navigationViewStyle(.stack)
    }
}
