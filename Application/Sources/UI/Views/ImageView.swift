//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import Nuke
import SwiftUI

// MARK: View

/// Behavior: h-exp, v-exp (like `Image/resizable()`)
struct ImageView: UIViewRepresentable {
    class Coordinator {
        /// The currently assigned URL. Useful to reset `isLoaded` when a URL change is detected.
        fileprivate var url: URL?
        /// Set to `true` when the next body update must be inhibited.
        fileprivate var skipNextUpdate: Bool = false
        /// The delayed `isLoaded` value to apply
        fileprivate var delayedIsLoaded: Bool = false
    }
    
    let url: URL?
    let contentMode: ContentMode
    let isBound: Bool
    
    @Binding var isLoaded: Bool
    
    init(url: URL?, contentMode: ContentMode = .fit) {
        self.init(url: url, contentMode: contentMode, isLoaded: .constant(false), isBound: false)
    }
    
    init(url: URL?, contentMode: ContentMode = .fit, isLoaded: Binding<Bool>) {
        self.init(url: url, contentMode: contentMode, isLoaded: isLoaded, isBound: true)
    }
    
    private init(url: URL?, contentMode: ContentMode = .fit, isLoaded: Binding<Bool>, isBound: Bool) {
        self.url = url
        self.contentMode = contentMode
        _isLoaded = isLoaded
        self.isBound = isBound
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator()
    }
    
    func makeUIView(context: Context) -> UIImageView {
        let imageView = UIImageView()
        imageView.applySizingBehavior(.expanding)
        return imageView
    }
    
    func updateUIView(_ uiView: UIImageView, context: Context) {
        if shouldSkipUpdate(context: context) {
            return
        }
        
        uiView.contentMode = Self.contentMode(contentMode)
        
        if context.coordinator.url != url {
            updateAfterDelay(isLoaded: false, context: context)
            context.coordinator.url = url
        }
        
        if let url = url {
            let options = ImageLoadingOptions(
                transition: .fadeIn(duration: 0.5)
            )
            
            Nuke.loadImage(with: url, options: options, into: uiView) { result in
                switch result {
                case .success:
                    updateAfterDelay(isLoaded: true, context: context)
                case .failure:
                    updateAfterDelay(isLoaded: false, context: context)
                }
            }
        }
        else {
            Nuke.cancelRequest(for: uiView)
            uiView.image = nil
        }
    }
    
    /**
     *  Update of the bindings must be made on the next run loop to avoid mutating a state while updating the body. To
     *  avoid this triggering additional body updates afterwards we need to be able to inhibit some updates.
     */
    private func updateAfterDelay(isLoaded: Bool, context: Context) {
        guard isBound else { return }
        
        // Store the value to apply on the next run loop
        context.coordinator.delayedIsLoaded = isLoaded
        
        // Schedule at most once update on the next run loop
        if !context.coordinator.skipNextUpdate {
            context.coordinator.skipNextUpdate = true
            
            DispatchQueue.main.async {
                // No change made, so no next body update will be triggered by the binding
                if self.isLoaded == context.coordinator.delayedIsLoaded {
                    context.coordinator.skipNextUpdate = false
                }
                // The change triggers a body update
                else {
                    self.isLoaded = context.coordinator.delayedIsLoaded
                }
            }
        }
    }
    
    /**
     *  The next body update must be skipped when this method returns `true`. This method also takes care of
     *  properly resetting the associated flag so that further updates can be properly processed.
     */
    private func shouldSkipUpdate(context: Context) -> Bool {
        guard isBound else { return false }
        
        let coordinator = context.coordinator
        if coordinator.skipNextUpdate {
            coordinator.skipNextUpdate = false
            return true
        }
        else {
            return false
        }
    }
    
    private static func contentMode(_ contentMode: ContentMode) -> UIView.ContentMode {
        switch contentMode {
        case .fit:
            return .scaleAspectFit
        case .fill:
            return .scaleAspectFill
        }
    }
}

// MARK: Preview

struct ImageView_Previews: PreviewProvider {
    private static let contentMode: ContentMode = .fill
    
    static var previews: some View {
        Group {
            ImageView(url: URL(string: "https://www.rts.ch/2020/11/09/11/29/11737826.image/16x9/scale/width/400")!)
            ImageView(url: URL(string: "https://www.rts.ch/2021/04/02/10/23/12095345.image/scale/width/400")!)
        }
        .aspectRatio(contentMode: .fit)
        .previewLayout(.fixed(width: 600, height: 600))
    }
}
