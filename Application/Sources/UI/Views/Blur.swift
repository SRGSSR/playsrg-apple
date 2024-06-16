//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

// MARK: View

// TODO: Can be removed when iOS 15+ is required (see https://www.hackingwithswift.com/quick-start/swiftui/how-to-add-visual-effect-blurs)

/**
 *  A view which blurs content behind it.
 */
struct Blur: UIViewRepresentable {
    let style: UIBlurEffect.Style

    func makeUIView(context _: Context) -> UIVisualEffectView {
        return UIVisualEffectView(effect: UIBlurEffect(style: style))
    }

    func updateUIView(_ uiView: UIVisualEffectView, context _: Context) {
        uiView.effect = UIBlurEffect(style: style)
    }
}
