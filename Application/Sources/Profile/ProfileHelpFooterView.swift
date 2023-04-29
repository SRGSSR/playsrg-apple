//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import UIKit

class ProfileHelpFooterView: UIView {
    private static let horizontalMargin: CGFloat = 16
    private static let verticalMargin: CGFloat = 8
    private static let height: CGFloat = HelpButton.height + 2 * verticalMargin
        
    @objc static func view() -> ProfileHelpFooterView {
        return ProfileHelpFooterView(frame: CGRect(x: 0, y: 0, width: 0, height: height))
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        layout()
    }
    
    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
        layout()
    }
    
    private func layout() {
        self.backgroundColor = .clear
        let helpButton = HostView<HelpButton>()
        self.addSubview(helpButton)
        
        helpButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            helpButton.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: Self.horizontalMargin),
            helpButton.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -Self.horizontalMargin),
            helpButton.topAnchor.constraint(equalTo: self.topAnchor, constant: Self.verticalMargin),
            helpButton.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -Self.verticalMargin)
        ])
        
        helpButton.content = HelpButton()
    }
}
