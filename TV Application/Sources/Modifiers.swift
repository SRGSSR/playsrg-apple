//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import FXReachability
import SwiftUI

extension View {
    /**
     *  Called when the application is woken up, either by the user or network being reachable again.
     */
    func onWake(perform action: @escaping () -> Void) -> some View {
        onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            action()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name.FXReachabilityStatusDidChange)) { _ in
            if FXReachability.isReachable() {
                action()
            }
        }
    }
}
