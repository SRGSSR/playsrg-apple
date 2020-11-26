//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGAnalytics
import SwiftUI

struct TrackerView: View {
    let title: String
    let levels: [String]?
    
    @State private var isDisplayed: Bool = false
    
    private func trackPageView() {
        SRGAnalyticsTracker.shared.trackPageView(withTitle: title, levels: levels)
    }
    
    var body: some View {
        Rectangle()
            .fill(Color.clear)
            .onAppear {
                if !isDisplayed {
                    trackPageView()
                    isDisplayed = true
                }
            }
            .onDisappear() {
                isDisplayed = false
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                if isDisplayed {
                    trackPageView()
                }
            }
    }
}

extension View {
    func tracked(with title: String, levels: [String]?) -> some View {
        self.background(TrackerView(title: title, levels: levels))
    }
}
