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
    
    var formattedTimeAndDate: String? {
        guard let program = program else { return nil }
        let startTime = DateFormatter.play_time.string(from: program.startDate)
        let endTime = DateFormatter.play_time.string(from: program.endDate)
        let day = DateFormatter.play_relative.string(from: program.startDate)
        return "\(startTime) - \(endTime), \(day)"
    }
    
    var imageUrl: URL? {
        return program?.imageUrl(for: .medium)
    }
    
    var imageCopyright: String? {
        guard let imageCopyright = program?.imageCopyright else { return nil }
        return String(format: NSLocalizedString("Image credit: %@", comment: "Image copyright introductory label"), imageCopyright)
    }
}
