//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

// MARK: View

struct EmptyContentView: View {
    enum Layout {
        case standard
        case text
    }

    let state: State
    let layout: Layout
    let insets: EdgeInsets

    init(state: State, layout: Layout = .standard, insets: EdgeInsets = .init(top: 0, leading: 0, bottom: 0, trailing: 0)) {
        self.state = state
        self.layout = layout
        self.insets = insets
    }

    private func largeImage(for type: Type) -> ImageResource {
        switch type {
        case .episodesFromFavorites, .favoriteShows:
            return .favoriteBackground
        case .generic:
            return .mediaBackground
        case .history, .resumePlayback:
            return .historyBackground
        case .search, .searchTutorial:
            return .searchBackground
        case .watchLater:
            return .watchLaterBackground
        #if os(iOS)
            case .notifications:
                return .subscriptionBackground
            case .downloads:
                return .downloadBackground
        #endif
        }
    }

    private func emptyTitle(for type: Type) -> String {
        switch type {
        case .favoriteShows:
            return NSLocalizedString("No favorites", comment: "Text displayed when no favorites are available")
        case .history:
            return NSLocalizedString("No history", comment: "Text displayed when no history is available")
        case .search:
            return NSLocalizedString("No results", comment: "Default text displayed when no results are available")
        case .searchTutorial:
            return NSLocalizedString("Type to start searching", comment: "Message displayed when there is no search criterium entered")
        #if os(iOS)
            case .notifications:
                return NSLocalizedString("No notifications", comment: "Text displayed when no notifications are available")
            case .downloads:
                return NSLocalizedString("No downloads", comment: "Text displayed when no downloads are available")
        #endif
        default:
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
                    if layout == .standard {
                        Image(largeImage(for: type))
                    }
                    Text(emptyTitle(for: type))
                        .srgFont(.H2)
                }
            case let .failed(error: error):
                VStack {
                    Image(.errorBackground)
                    Text(error.localizedDescription)
                        .srgFont(.H4)
                }
            }
        }
        .multilineTextAlignment(.center)
        .lineLimit(3)
        .foregroundColor(.srgGrayD2)
        .padding()
        .padding(insets)
    }
}

// MARK: Types

extension EmptyContentView {
    enum State {
        case loading
        case empty(type: Type)
        case failed(error: Error)
    }

    enum `Type`: Hashable {
        case episodesFromFavorites
        case favoriteShows
        case generic
        case history
        case resumePlayback
        case search
        case searchTutorial
        case watchLater
        #if os(iOS)
            case notifications
            case downloads
        #endif
    }
}

// MARK: Preview

struct EmptyContentView_Previews: PreviewProvider {
    enum PreviewError: LocalizedError {
        case kernel32

        var errorDescription: String? {
            switch self {
            case .kernel32:
                "Error loading kernel32.dll. The specified module could not be found."
            }
        }
    }

    static var previews: some View {
        Group {
            Group {
                EmptyContentView(state: .empty(type: .episodesFromFavorites))
                EmptyContentView(state: .empty(type: .favoriteShows))
                EmptyContentView(state: .empty(type: .generic))
                EmptyContentView(state: .empty(type: .history))
                #if os(iOS)
                    EmptyContentView(state: .empty(type: .downloads))
                #endif
            }
            Group {
                EmptyContentView(state: .empty(type: .resumePlayback))
                EmptyContentView(state: .empty(type: .search))
                EmptyContentView(state: .empty(type: .searchTutorial))
                EmptyContentView(state: .empty(type: .watchLater))
            }
            Group {
                EmptyContentView(state: .loading)
                EmptyContentView(state: .failed(error: PreviewError.kernel32))
            }
        }
        .previewLayout(.fixed(width: 400, height: 400))
    }
}
