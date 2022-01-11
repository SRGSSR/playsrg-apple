//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

// MARK: Types

// MARK: View

struct EmptyView: View {
    enum State {
        case loading
        case empty(type: `Type`)
        case failed(error: Error)
    }
    
    enum `Type`: Hashable {
        case episodesFromFavorites
        case favoriteShows
        case generic
        case history
        case resumePlayback
        case search
        case watchLater
    }
    
    let state: State
    
    private func imageName(for type: `Type`) -> String {
        switch type {
        case .episodesFromFavorites, .favoriteShows:
            return "favorite-background"
        case .generic:
            return "media-background"
        case .history, .resumePlayback:
            return "history-background"
        case .search:
            return "search-background"
        case .watchLater:
            return "watch_later-background"
        }
    }
    
    private func emptyTitle(for type: `Type`) -> String {
        switch type {
        case .favoriteShows:
            return NSLocalizedString("No favorites", comment: "Text displayed when no favorites are available")
        case .history:
            return NSLocalizedString("No history", comment: "Text displayed when no history is available")
        case .search:
            return NSLocalizedString("No results", comment: "Default text displayed when no results are available");
        case .episodesFromFavorites, .generic, .resumePlayback, .watchLater:
            return NSLocalizedString("No content", comment: "Default text displayed when no content is available")
        }
    }
    
    var body: some View {
        Group {
            switch state {
            case .loading:
                ActivityIndicator()
            case let .empty(type: type):
                VStack {
                    Image(imageName(for: type))
                    Text(emptyTitle(for: type))
                        .srgFont(.H2)
                }
            case let .failed(error: error):
                VStack {
                    Image("error-background")
                    Text(error.localizedDescription)
                        .srgFont(.H4)
                }
            }
        }
        .multilineTextAlignment(.center)
        .lineLimit(3)
        .foregroundColor(Color.srgGrayC7)
        .padding()
    }
}

// MARK: Preview

struct EmptyView_Previews: PreviewProvider {
    enum PreviewError: LocalizedError {
        case kernel32
        
        var errorDescription: String? {
            switch self {
            case .kernel32:
                return "Error loading kernel32.dll. The specified module could not be found."
            }
        }
    }
    
    static var previews: some View {
        Group {
            EmptyView(state: .loading)
            EmptyView(state: .empty(type: .episodesFromFavorites))
            EmptyView(state: .empty(type: .favoriteShows))
            EmptyView(state: .empty(type: .generic))
            EmptyView(state: .empty(type: .history))
            EmptyView(state: .empty(type: .resumePlayback))
            EmptyView(state: .empty(type: .search))
            EmptyView(state: .empty(type: .watchLater))
            EmptyView(state: .failed(error: PreviewError.kernel32))
        }
        .previewLayout(.fixed(width: 400, height: 400))
    }
}
