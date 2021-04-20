//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI
import UIKit

/**
 *  Collection view cell hosting `SwiftUI` content.
 */
class HostCollectionViewCell<Content: View>: UICollectionViewCell {
    private var hostController: UIHostingController<Content>?
    
    private func addHostController(for content: Content?) {
        guard let rootView = content else { return }
        hostController = UIHostingController(rootView: rootView, ignoreSafeArea: true)
        if let hostView = hostController?.view {
            hostView.frame = contentView.bounds
            hostView.backgroundColor = .clear
            hostView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            contentView.addSubview(hostView)
        }
    }
    
    private func removeHostController() {
        if let hostView = hostController?.view {
            hostView.removeFromSuperview()
        }
        hostController = nil
    }
    
    override func prepareForReuse() {
        removeHostController()
    }
    
    var content: Content? {
        didSet {
            removeHostController()
            addHostController(for: content)
        }
    }
}

/**
 *  Collection view reusable view hosting `SwiftUI` content.
 */
class HostSupplementaryView<Content: View>: UICollectionReusableView {
    private var hostController: UIHostingController<Content>?
    
    private func addHostController(for content: Content?) {
        guard let rootView = content else { return }
        hostController = UIHostingController(rootView: rootView, ignoreSafeArea: true)
        if let hostView = hostController?.view {
            hostView.frame = bounds
            hostView.backgroundColor = .clear
            hostView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            addSubview(hostView)
        }
    }
    
    private func removeHostController() {
        if let hostView = hostController?.view {
            hostView.removeFromSuperview()
        }
        hostController = nil
    }
    
    override func prepareForReuse() {
        removeHostController()
    }
    
    var content: Content? {
        didSet {
            removeHostController()
            addHostController(for: content)
        }
    }
}

/**
 *  Table view cell hosting `SwiftUI` content.
 */
class HostTableViewCell<Content: View>: UITableViewCell {
    private var hostController: UIHostingController<Content>?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.tintColor = .red
        self.backgroundColor = .clear
        
        let selectedBackgroundView = UIView()
        selectedBackgroundView.backgroundColor = .clear
        self.selectedBackgroundView = selectedBackgroundView
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func addHostController(for content: Content?) {
        guard let rootView = content else { return }
        hostController = UIHostingController(rootView: rootView, ignoreSafeArea: true)
        if let hostView = hostController?.view {
            hostView.frame = contentView.bounds
            hostView.backgroundColor = .clear
            hostView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            contentView.addSubview(hostView)
        }
    }
    
    private func removeHostController() {
        if let hostView = hostController?.view {
            hostView.removeFromSuperview()
        }
        hostController = nil
    }
    
    override func prepareForReuse() {
        removeHostController()
    }
    
    var content: Content? {
        didSet {
            removeHostController()
            addHostController(for: content)
        }
    }
}
