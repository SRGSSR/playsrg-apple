//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

// MARK: View

struct FeaturesView: View {
    var body: some View {
        List {
            ForEach(Onboarding.onboardings, id: \.uid) { onboarding in
                OnboardingCell(onboarding: onboarding)
            }
        }
        .navigationTitle(NSLocalizedString("Features", comment: "Title displayed at the top of the Features view"))
    }
    
    private struct OnboardingCell: View {
        let onboarding: Onboarding
        
        var body: some View {
            HStack {
                Image(decorative: onboarding.iconName)
                Text(onboarding.title)
            }
        }
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
