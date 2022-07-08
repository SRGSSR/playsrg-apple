//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import Introspect
import SRGAppearanceSwift
import SwiftUI

func PlayNavigationView<Content: View>(@ViewBuilder content: () -> Content) -> AnyView {
    return NavigationView(content: content)
        .introspectNavigationController { navigationController in
            let navigationBar = navigationController.navigationBar
#if os(iOS)
            navigationBar.largeTitleTextAttributes = [
                .font: SRGFont.font(family: .display, weight: .bold, fixedSize: 34) as UIFont
            ]
#endif
            navigationBar.titleTextAttributes = [
                .font: SRGFont.font(family: .display, weight: .semibold, fixedSize: 17) as UIFont
            ]
        }
        .eraseToAnyView()
}