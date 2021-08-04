//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import Foundation

// MARK: View model

final class ProgramViewModel: ObservableObject {
    @Published var program: SRGProgram?
    
    var title: String? {
        return program?.title
    }
    
    var lead: String? {
        return program?.lead
    }
    
    var summary: String? {
        return program?.summary
    }
    
    var imageUrl: URL? {
        return program?.imageUrl(for: .medium)
    }
}
