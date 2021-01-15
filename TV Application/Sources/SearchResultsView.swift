//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

// TODO: Somehow make searchController.searchControllerObservedScrollView = scrollView possible for SwiftUI views
//       (in particular our CollectionView)
struct SearchResultsView: View {
    @ObservedObject var model: SearchResultsModel
    
    private var text: String {
        if let query = model.query, !query.isEmpty {
            return query
        }
        else {
            return "Type to search"
        }
    }
    
    var body: some View {
        Text(text)
    }
}
