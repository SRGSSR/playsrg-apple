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
        case empty
        case failed(error: Error)
    }
    
    let state: State
    
    var body: some View {
        Group {
            switch state {
            case .loading:
                ActivityIndicator()
            case .empty:
                VStack {
                    Image("media-background")
                    Text(NSLocalizedString("No results", comment: "Default text displayed when no results are available"))
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
        .foregroundColor(Color.srgGray5)
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
            EmptyView(state: .empty)
            EmptyView(state: .failed(error: PreviewError.kernel32))
        }
        .previewLayout(.fixed(width: 400, height: 400))
    }
}
