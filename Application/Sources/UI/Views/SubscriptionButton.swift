//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

// MARK: View

/// Behavior: h-hug, v-hug
struct SubscriptionButton: View {
    var show: SRGShow?
    
    private var isPushServiceEnabled: Bool {
        if let pushService = PushService.shared {
            return pushService.isEnabled
        }
        else {
            return false
        }
    }
    
    private var imageName: String {
        if isPushServiceEnabled, let show = show {
            return FavoritesIsSubscribedToShow(show) ? "subscription_full-22" : "subscription-22"
        }
        else {
            return "subscription_disabled-22"
        }
    }
    
    private var accessibilityLabel: String {
        if isPushServiceEnabled, let show = show {
            return FavoritesIsSubscribedToShow(show) ? PlaySRGAccessibilityLocalizedString("Disable notifications for show", "Show unsubscription label") : PlaySRGAccessibilityLocalizedString("Enable notifications for show", "Show subscription label")
        }
        else {
            return PlaySRGAccessibilityLocalizedString("Enable notifications for show", "Show subscription label")
        }
    }
        
    var body: some View {
        Button {
            guard let show = show, FavoritesToggleSubscriptionForShow(show) else { return }
            
            let subscribed = FavoritesIsSubscribedToShow(show)
            
            let analyticsTitle = subscribed ? AnalyticsTitle.subscriptionAdd : AnalyticsTitle.subscriptionRemove
            let labels = SRGAnalyticsHiddenEventLabels()
            labels.source = AnalyticsSource.button.rawValue
            labels.value = show.urn
            SRGAnalyticsTracker.shared.trackHiddenEvent(withName: analyticsTitle.rawValue, labels: labels)
            
            Banner.showSubscription(subscribed, forShowWithName: show.title)
        } label: {
            Image(imageName)
        }
        .foregroundColor(.white)
        .accessibilityLabel(accessibilityLabel)
    }
}

// MARK: Preview

struct SubscriptionButton_Previews: PreviewProvider {
    static var previews: some View {
        SubscriptionButton()
    }
}
