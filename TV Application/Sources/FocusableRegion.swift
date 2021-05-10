//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

/**
 *  A view able to catch focus.
 */
private struct FocusableRegion<Content: View>: UIViewControllerRepresentable {
    private let content: () -> Content
    
    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }
    
    func makeUIViewController(context: Context) -> UIHostingController<Content> {
        let hostController = UIHostingController(rootView: content(), ignoreSafeArea: true)
        
        if let hostView = hostController.view {
            let focusGuide = UIFocusGuide()
            focusGuide.preferredFocusEnvironments = [WeakFocusEnvironment(hostView)]
            hostView.addLayoutGuide(focusGuide)
            
            NSLayoutConstraint.activate([
                focusGuide.topAnchor.constraint(equalTo: hostView.topAnchor),
                focusGuide.bottomAnchor.constraint(equalTo: hostView.bottomAnchor),
                focusGuide.leadingAnchor.constraint(equalTo: hostView.leadingAnchor),
                focusGuide.trailingAnchor.constraint(equalTo: hostView.trailingAnchor)
            ])
        }
        
        return hostController
    }
    
    func updateUIViewController(_ uiViewController: UIHostingController<Content>, context: Context) {
        uiViewController.rootView = content()
    }
}

extension FocusableRegion {
    /**
     *  A focus environment wrapper that avoids retaining its wrapped object.
     */
    class WeakFocusEnvironment: NSObject, UIFocusEnvironment {
        weak var wrappedEnvironment: UIFocusEnvironment?
        
        init(_ wrappedEnvironment: UIFocusEnvironment) {
            self.wrappedEnvironment = wrappedEnvironment
        }
        
        var preferredFocusEnvironments: [UIFocusEnvironment] {
            return wrappedEnvironment?.preferredFocusEnvironments ?? []
        }
        
        var parentFocusEnvironment: UIFocusEnvironment? {
            return wrappedEnvironment?.parentFocusEnvironment
        }
        
        var focusItemContainer: UIFocusItemContainer? {
            return wrappedEnvironment?.focusItemContainer
        }
        
        func setNeedsFocusUpdate() {
            wrappedEnvironment?.setNeedsFocusUpdate()
        }
        
        func updateFocusIfNeeded() {
            wrappedEnvironment?.updateFocusIfNeeded()
        }
        
        func shouldUpdateFocus(in context: UIFocusUpdateContext) -> Bool {
            return wrappedEnvironment?.shouldUpdateFocus(in: context) ?? false
        }
        
        func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
            wrappedEnvironment?.didUpdateFocus(in: context, with: coordinator)
        }
    }
}

extension View {
    /**
     *  Ensure the whole view area can catch focus, redirecting it onto itself.
     */
    func focusable() -> some View {
        return FocusableRegion {
            self
        }
    }
}
