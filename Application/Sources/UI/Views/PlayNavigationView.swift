//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGAppearanceSwift
import SwiftUI
import SwiftUIIntrospect

func PlayNavigationView(@ViewBuilder content: () -> some View) -> AnyView {
    NavigationView(content: content)
        .navigationViewStyle(.stack)
        .introspect(.navigationView(style: .stack), on: .iOS(.v14, .v15, .v16, .v17), .tvOS(.v14, .v15, .v16, .v17)) {
            let navigationBar = $0.navigationBar
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
