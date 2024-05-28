//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

struct MediaMoreButton: UIViewRepresentable {
    typealias UIViewType = UIButton
    
    let media: SRGMedia
    
    func makeUIView(context: Context) -> UIButton {
        let button = UIButton(type: .custom)
        button.setImage(UIImage(resource: .ellipsis), for: .normal)
        button.tintColor = .srgGrayD2
        
        button.showsMenuAsPrimaryAction = true
        button.menu = UIMenu()
        button.addAction(UIAction(handler: { _ in
            if let viewController = button.play_nearestViewController {
                button.menu = ContextMenu.menu(for: media, in: viewController)
            }
        }), for: .menuActionTriggered)
        
        button.setContentHuggingPriority(.required, for: .horizontal)
        button.setContentHuggingPriority(.required, for: .vertical)
        
        return button
    }
    
    func updateUIView(_ uiView: UIButton, context: Context) {
        // No update logic required
    }
}

// MARK: Accessibility

private extension MediaMoreButton {
    var accessibilityLabel: String? {
        return PlaySRGAccessibilityLocalizedString("More", comment: "More button label")
    }
}

struct MoreButton_Previews: PreviewProvider {
    static var previews: some View {
        MediaMoreButton(media: Mock.media())
            .previewLayout(.sizeThatFits)
    }
}
