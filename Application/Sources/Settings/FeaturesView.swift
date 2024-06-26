//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGAnalyticsSwiftUI
import SRGAppearanceSwift
import SwiftUI

// MARK: View

struct FeaturesView: View {
    @State private var selectedOnboarding: Onboarding?

    var body: some View {
        List {
            ForEach(Onboarding.onboardings) { onboarding in
                Button {
                    selectedOnboarding = onboarding
                } label: {
                    OnboardingCell(onboarding: onboarding)
                }
            }
        }
        .srgFont(.body)
        .navigationTitle(NSLocalizedString("Features", comment: "Title displayed at the top of the Features view"))
        .fullScreenCover(item: $selectedOnboarding) { onboarding in
            OnboardingView(onboarding: onboarding)
                .ignoresSafeArea()
        }
        .tracked(withTitle: analyticsPageTitle, type: AnalyticsPageType.help.rawValue, levels: analyticsPageLevels)
    }

    private struct OnboardingCell: View {
        let onboarding: Onboarding

        var body: some View {
            HStack {
                Image(decorative: onboarding.iconName)
                Text(onboarding.title)
            }
            .foregroundColor(.primary)
        }
    }
}

// MARK: Analytics

private extension FeaturesView {
    private var analyticsPageTitle: String {
        AnalyticsPageTitle.features.rawValue
    }

    private var analyticsPageLevels: [String]? {
        [AnalyticsPageLevel.play.rawValue, AnalyticsPageLevel.application.rawValue]
    }
}

// MARK: Preview

struct FeaturesView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            FeaturesView()
        }
        .navigationViewStyle(.stack)
    }
}
