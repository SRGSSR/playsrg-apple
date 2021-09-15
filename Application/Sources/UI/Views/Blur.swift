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
private struct Blur: UIViewRepresentable {
    let style: UIBlurEffect.Style
    
    func makeUIView(context: Context) -> UIVisualEffectView {
        return UIVisualEffectView(effect: UIBlurEffect(style: style))
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: style)
    }
}

// MARK: Extensions

extension View {
    /**
     *  Apply a transluscent background.
     */
    func transluscentBackground() -> some View {
#if os(iOS)
        // TODO: When iOS 15 is the minimum supported version, replace with background(.thinMaterial)
        return background(Blur(style: .systemThinMaterial))
#else
        return background(Color.clear)
#endif
    }
}
