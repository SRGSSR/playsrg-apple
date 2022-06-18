//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGAnalyticsSwiftUI
import SwiftUI

// MARK: View

// TODO: Rewrite Onboarding type in Swift
extension Onboarding: Identifiable {
    public var id: String {
        return uid
    }
}

struct FeaturesView: View {
    @State private var selectedOnboarding: Onboarding?
    
    var body: some View {
        List {
            ForEach(Onboarding.onboardings, id: \.uid) { onboarding in
                Button {
                    selectedOnboarding = onboarding
                } label: {
                    OnboardingCell(onboarding: onboarding)
                }
            }
        }
        .navigationTitle(NSLocalizedString("Features", comment: "Title displayed at the top of the Features view"))
        .fullScreenCover(item: $selectedOnboarding) { onboarding in
            OnboardingView(onboarding: onboarding)
                .ignoresSafeArea()
        }
        .tracked(withTitle: analyticsPageTitle, levels: analyticsPageLevels)
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
        return AnalyticsPageTitle.features.rawValue
    }
    
    private var analyticsPageLevels: [String]? {
        return [AnalyticsPageLevel.play.rawValue, AnalyticsPageLevel.application.rawValue]
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
