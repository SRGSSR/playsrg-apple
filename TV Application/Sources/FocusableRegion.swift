//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

struct FocusableRegion<Content: View>: UIViewRepresentable {
    class Coordinator {
        fileprivate var hostController: UIHostingController<Content>?
    }
    
    private let content: () -> Content
    
    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator()
    }
    
    func makeUIView(context: Context) -> UIView {
        let hostController = UIHostingController(rootView: content(), ignoreSafeArea: true)
        context.coordinator.hostController = hostController
        
        let hostView = hostController.view!
        
        let focusGuide = UIFocusGuide()
        focusGuide.preferredFocusEnvironments = [hostView]
        hostView.addLayoutGuide(focusGuide)
        
        NSLayoutConstraint.activate([
            focusGuide.topAnchor.constraint(equalTo: hostView.topAnchor),
            focusGuide.bottomAnchor.constraint(equalTo: hostView.bottomAnchor),
            focusGuide.leadingAnchor.constraint(equalTo: hostView.leadingAnchor),
            focusGuide.trailingAnchor.constraint(equalTo: hostView.trailingAnchor)
        ])
        
        return hostView
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.hostController?.rootView = content()
    }
}
