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
        case empty(contentType: ContentType)
        case failed(error: Error)
    }
    
    enum ContentType {
        case favoriteShows
        case history
        case watchLater
        case any
    }
    
    let state: State
    
    private func imageName(for contentType: ContentType) -> String {
        switch contentType {
        case .favoriteShows:
            return "favorite-background"
        case .history:
            return "history-background"
        case .watchLater:
            return "watch_later_background"
        case .any:
            return "media-background"
        }
    }
    
    private func emtpyTitle(for contentType: ContentType) -> String {
        switch contentType {
        case .favoriteShows:
            return NSLocalizedString("No favorites", comment: "Text displayed when no favorites are available")
        case .history:
            return NSLocalizedString("No history", comment: "Text displayed when no history is available")
        case .watchLater:
            return NSLocalizedString("No content", comment: "Text displayed when no media added to the later list")
        case .any:
            return NSLocalizedString("No results", comment: "Default text displayed when no results are available")
        }
    }
    
    var body: some View {
        Group {
            switch state {
            case .loading:
                ActivityIndicator()
            case let .empty(contentType: contentType):
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
            EmptyView(state: .empty(contentType: .favoriteShows))
            EmptyView(state: .empty(contentType: .history))
            EmptyView(state: .empty(contentType: .watchLater))
            EmptyView(state: .empty(contentType: .any))
            EmptyView(state: .failed(error: PreviewError.kernel32))
        }
        .previewLayout(.fixed(width: 400, height: 400))
    }
}
