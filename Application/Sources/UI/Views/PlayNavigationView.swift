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
            navigationBar.largeTitleTextAttributes = [
                .font: SRGFont.font(family: .display, weight: .bold, size: 34) as UIFont
            ]
            navigationBar.titleTextAttributes = [
                .font: SRGFont.font(family: .display, weight: .semibold, size: 17) as UIFont
            ]
        }
        .eraseToAnyView()
}
