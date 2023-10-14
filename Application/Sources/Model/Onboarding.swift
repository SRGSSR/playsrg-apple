//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import Foundation

struct Onboarding: Codable, Identifiable {
    static let onboardings: [Self] = {
        let fileUrl = Bundle.main.url(forResource: "Onboardings", withExtension: "json")!
        let data = try! Data(contentsOf: fileUrl)
        return try! JSONDecoder().decode([Self].self, from: data)
            .filter { !ApplicationConfiguration.shared.hiddenOnboardingUids.contains($0.id) }
    }()
    
    let id: String
    let title: String
    let pages: [OnboardingPage]
    
    var icon: ImageResource {
        return ImageResource(name: "\(id)_icon", bundle: .main)
    }
}
