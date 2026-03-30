//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGAppearanceSwift
import SwiftUI

func PlaySection(@ViewBuilder content: () -> some View, @ViewBuilder header: () -> some View, @ViewBuilder footer: () -> some View) -> Section<AnyView, AnyView, AnyView> {
    Section {
        content()
            .srgFont(.body)
#if os(tvOS)
            .tvOS17_backgroundFix()
#endif
            .eraseToAnyView()
    } header: {
        header()
            .srgFont(.H2)
            .foregroundColor(.srgGray96)
            .eraseToAnyView()
    } footer: {
        footer()
            .srgFont(.subtitle2)
            .foregroundColor(.srgGray96)
            .eraseToAnyView()
    }
}

private extension View {
    @available(iOS, unavailable)
    @ViewBuilder
    func tvOS17_backgroundFix() -> some View {
        if ProcessInfo.processInfo.operatingSystemVersion.majorVersion == 17 {
            // tvOS 17.0 introduced a new issue when presenting modal, the default focused appearance is broken after modal presentation dismissal. See https://github.com/SRGSSR/playsrg-apple/issues/336
            foregroundColor(.white)
                .listRowBackground(Color.srgGray33.cornerRadius(10))
        }
        else {
            self
        }
    }
}

func PlaySection(@ViewBuilder content: () -> some View, @ViewBuilder header: () -> some View) -> Section<AnyView, AnyView, AnyView> {
    PlaySection(content: content, header: header) {
        EmptyView()
    }
}

func PlaySection(@ViewBuilder content: () -> some View, @ViewBuilder footer: () -> some View) -> Section<AnyView, AnyView, AnyView> {
    PlaySection(content: content, header: {
        EmptyView()
    }, footer: footer)
}

func PlaySection(@ViewBuilder content: () -> some View) -> Section<AnyView, AnyView, AnyView> {
    PlaySection(content: content) {
        EmptyView()
    } footer: {
        EmptyView()
    }
}

extension Color {
    static var play_sectionSecondary: Color {
        // tvOS 17.0 introduced a new issue when presenting modal, the default focused appearance is broken after modal presentation dismissal. See https://github.com/SRGSSR/playsrg-apple/issues/336
        constant(iOS: .secondary, tvOS: .white)
    }
}
