//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import Foundation
import SRGAppearance

struct OnboardingPage: Codable, Identifiable {
    let id: String
    let title: String
    let text: String
    
    private let colorHex: String
    
    enum CodingKeys: String, CodingKey {
        case id, title, text
        case colorHex = "color"
    }
    
    func image(for onboarding: Onboarding) -> ImageResource {
        return ImageResource(name: "\(onboarding.id)_\(id)", bundle: .main)
    }
    
    func icon(for onboarding: Onboarding) -> ImageResource {
        return ImageResource(name: "\(onboarding.id)_\(id)-small", bundle: .main)
    }
    
    var color: UIColor {
        return .hexadecimal(colorHex) ?? .white
    }
}
