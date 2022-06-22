//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGAppearanceSwift
import SwiftUI

// MARK: View

struct SearchSettingsBucketsView: View {
    @ObservedObject var model = SearchSettingsViewModel()
    
    enum Kind: String {
        case topics
        case shows
    }
    
    let kind: Kind
    
    private var title: String {
        switch kind {
        case .topics:
            return NSLocalizedString("Topics", comment: "Search setting")
        case .shows:
            return NSLocalizedString("Shows", comment: "Search setting")
        }
    }
    
    private var buckets: [SearchSettingsViewModel.SearchSettingsBucket] {
        switch kind {
        case .topics:
            return model.topicBuckets
        case .shows:
            return model.showsBuckets
        }
    }
    
    var body: some View {
        List(buckets) {
            Text($0.title)
        }
        .srgFont(.body)
        .navigationTitle(title)
    }
}

struct SearchSettingsBucketsView_Previews: PreviewProvider {
    static var previews: some View {
        SearchSettingsBucketsView(kind: .topics)
    }
}
