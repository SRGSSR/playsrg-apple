//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

// MARK: View

struct OnboardingView: UIViewControllerRepresentable {
    let onboarding: Onboarding

    func makeUIViewController(context _: Context) -> OnboardingViewController {
        return .viewController(for: onboarding)
    }

    func updateUIViewController(_: OnboardingViewController, context _: Context) {
        // Never updated
    }
}

// MARK: Preview

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView(onboarding: Onboarding.onboardings.first!)
    }
}
