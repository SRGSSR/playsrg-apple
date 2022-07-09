//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import Foundation

struct Onboarding: Codable, Identifiable {
    static let onboardings: [Onboarding] = {
        let fileUrl = Bundle.main.url(forResource: "Onboardings", withExtension: "json")!
        let data = try! Data(contentsOf: fileUrl)
        return try! JSONDecoder().decode([Onboarding].self, from: data)
            .filter { !ApplicationConfiguration.shared.hiddenOnboardingUids.contains($0.id) }
    }()
    
    let id: String
    let title: String
    let pages: [OnboardingPage]
    
    var iconName: String {
        return "\(id)_icon"
    }
}
