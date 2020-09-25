//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import FXReachability
import SwiftUI

extension View {
    func onResume(perform action: @escaping () -> Void) -> some View {
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
