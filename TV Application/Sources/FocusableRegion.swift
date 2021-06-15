//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

/**
 *  A view able to catch focus.
 *
 *  Behavior: h-neu, v-neu
 */
private struct FocusableRegion<Content: View>: UIViewRepresentable {
    private let content: () -> Content
    
    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }
    
    func makeCoordinator() -> UIHostingController<Content> {
        return UIHostingController(rootView: content(), ignoreSafeArea: true)
    }
    
    func makeUIView(context: Context) -> UIView {
        let hostView = context.coordinator.view!
        hostView.backgroundColor = .clear
        
        let focusGuide = UIFocusGuide()
        focusGuide.preferredFocusEnvironments = [WeakFocusEnvironment(hostView)]
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
        let hostController = context.coordinator
        hostController.rootView = content()
        
        // Make layout neutral
        uiView.applySizingBehavior(of: hostController)
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

struct FocusableRegion_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            FocusableRegion {
                Color.red
            }
            FocusableRegion {
                Text("Text")
            }
        }
        .border(Color.blue, width: 3)
        .previewLayout(.fixed(width: 400, height: 400))
    }
}
