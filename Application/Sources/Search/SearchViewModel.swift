//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import Combine

// MARK: View model

final class SearchViewModel: ObservableObject {
    @Published private(set) var state = State.loading
    
    var query: String {
        get {
            querySubject.value
        }
        set {
            querySubject.value = newValue
        }
    }
    
    private var querySubject = CurrentValueSubject<String, Never>("")
}

// MARK: Types

extension SearchViewModel {
    enum State {
        case loading
        case failed(error: Error)
        case mostSearched(shows: [SRGShow])
        case loaded(medias: [SRGMedia], suggestions: [SRGSearchSuggestion])
    }
}
