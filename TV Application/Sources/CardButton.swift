//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

fileprivate struct CardButton<Content: View>: View {
    private let action: (() -> Void)?
    private let content: () -> Content
    
    init(action: (() -> Void)?, @ViewBuilder content: @escaping () -> Content) {
        self.action = action
        self.content = content
    }
    
    var body: some View {
        GeometryReader { geometry in
            Button(action: {
                if let action = action {
                    action()
                }
            }) {
                content()
                    .frame(width: geometry.size.width, height: geometry.size.height)
            }
            .buttonStyle(CardButtonStyle())
        }
    }
}

extension View {
    /**
     *  Wrap into a card button with associated optional action.
     */
    func cardButton(action: (() -> Void)? = nil) -> some View {
        return CardButton(action: action) {
            self
        }
    }
}
