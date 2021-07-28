//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

// MARK: View

struct EmptyView: View {
    enum State {
        case loading
        case empty(type: Content.EmptyType)
        case failed(error: Error)
    }
    
    let state: State
    
    private func imageName(for emptyType: Content.EmptyType) -> String {
        switch emptyType {
        case .favoriteShows, .episodesFromFavorites:
            return "favorite-background"
        case .history, .resumePlayback:
            return "history-background"
        case .watchLater:
            return "watch_later-background"
        case .any:
            return "media-background"
        }
    }
    
    private func emtpyTitle(for emptyType: Content.EmptyType) -> String {
        switch emptyType {
        case .favoriteShows:
            return NSLocalizedString("No favorites", comment: "Text displayed when no favorites are available")
        case .history:
            return NSLocalizedString("No history", comment: "Text displayed when no history is available")
        case .watchLater, .resumePlayback, .episodesFromFavorites:
            return NSLocalizedString("No content", comment: "Text displayed when no media added or displayed in a list")
        case .any:
            return NSLocalizedString("No results", comment: "Default text displayed when no results are available")
        }
    }
    
    var body: some View {
        Group {
            switch state {
            case .loading:
                ActivityIndicator()
            case let .empty(type: contentType):
                VStack {
                    Image(imageName(for: contentType))
                    Text(emtpyTitle(for: contentType))
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
            EmptyView(state: .empty(type: .favoriteShows))
            EmptyView(state: .empty(type: .episodesFromFavorites))
            EmptyView(state: .empty(type: .history))
            EmptyView(state: .empty(type: .resumePlayback))
            EmptyView(state: .empty(type: .watchLater))
            EmptyView(state: .empty(type: .any))
            EmptyView(state: .failed(error: PreviewError.kernel32))
        }
        .previewLayout(.fixed(width: 400, height: 400))
    }
}
