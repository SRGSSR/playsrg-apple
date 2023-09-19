//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGAppearanceSwift
import SwiftUI

func PlaySection<Content: View, Header: View, Footer: View>(@ViewBuilder content: () -> Content, @ViewBuilder header: () -> Header, @ViewBuilder footer: () -> Footer) -> Section<AnyView, AnyView, AnyView> {
    return Section {
        content()
            .srgFont(.body)
#if os(tvOS)
        // tvOS 17.0 introduced a new issue when presenting modal, the default focused appearance is broken after modal presentation dismissal. See https://github.com/SRGSSR/playsrg-apple/issues/336
            .foregroundColor(.white)
            .listRowBackground(Color.srgGray33.cornerRadius(10))
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

func PlaySection<Content: View, Header: View>(@ViewBuilder content: () -> Content, @ViewBuilder header: () -> Header) -> Section<AnyView, AnyView, AnyView> {
    return PlaySection(content: content, header: header) {
        EmptyView()
    }
}

func PlaySection<Content: View, Footer: View>(@ViewBuilder content: () -> Content, @ViewBuilder footer: () -> Footer) -> Section<AnyView, AnyView, AnyView> {
    return PlaySection(content: content, header: {
        EmptyView()
    }, footer: footer)
}

func PlaySection<Content: View>(@ViewBuilder content: () -> Content) -> Section<AnyView, AnyView, AnyView> {
    return PlaySection(content: content) {
        EmptyView()
    } footer: {
        EmptyView()
    }
}
