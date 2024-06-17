//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI
import UIKit

/**
 *  Internal wrapper to bridge UIKit cell properties with SwiftUI environment.
 */
struct HostCellView<Content: View>: View {
    let isEditing: Bool
    let isSelected: Bool
    let isUIKitFocused: Bool
    @Binding private var content: Content

    init(editing: Bool, selected: Bool, UIKitFocused: Bool, content: Content) {
        isEditing = editing
        isSelected = selected
        isUIKitFocused = UIKitFocused

        _content = .constant(content)
    }

    var body: some View {
        content
            .environment(\.isEditing, isEditing)
            .environment(\.isSelected, isSelected)
            .environment(\.isUIKitFocused, isUIKitFocused)
    }
}

/**
 *  Collection view cell hosting `SwiftUI` content.
 */
class HostCollectionViewCell<Content: View>: UICollectionViewCell {
    private(set) var hostController: UIHostingController<HostCellView<Content>>?

    private func update(with content: Content?, editing: Bool, selected: Bool, UIKitFocused: Bool) {
        if let content {
            let rootView = HostCellView(editing: editing, selected: selected, UIKitFocused: UIKitFocused, content: content)
            if let hostController {
                hostController.rootView = rootView
            } else {
                hostController = UIHostingController(rootView: rootView, ignoreSafeArea: true)
            }

            if let hostView = hostController?.view, hostView.superview != contentView {
                hostView.backgroundColor = .clear
                contentView.addSubview(hostView)

                hostView.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    hostView.topAnchor.constraint(equalTo: contentView.topAnchor),
                    hostView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
                    hostView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                    hostView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
                ])
            }
        } else if let hostView = hostController?.view {
            hostView.removeFromSuperview()
        }
    }

    var content: Content? {
        didSet {
            update(with: content, editing: isEditing, selected: isSelected, UIKitFocused: isUIKitFocused)
        }
    }

    private var isEditing: Bool {
        guard let collectionView = superview as? UICollectionView else { return false }
        return collectionView.isEditing
    }

    override var isSelected: Bool {
        didSet {
            update(with: content, editing: isEditing, selected: isSelected, UIKitFocused: isUIKitFocused)
        }
    }

    var isUIKitFocused = false {
        didSet {
            update(with: content, editing: isEditing, selected: isSelected, UIKitFocused: isUIKitFocused)
        }
    }
}

/**
 *  Collection view reusable view hosting `SwiftUI` content.
 */
class HostSupplementaryView<Content: View>: UICollectionReusableView {
    private(set) var hostController: UIHostingController<Content>?

    private func update(with content: Content?) {
        if let rootView = content {
            if let hostController {
                hostController.rootView = rootView
            } else {
                hostController = UIHostingController(rootView: rootView, ignoreSafeArea: true)
            }

            if let hostView = hostController?.view, hostView.superview != self {
                hostView.backgroundColor = .clear
                addSubview(hostView)

                hostView.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    hostView.topAnchor.constraint(equalTo: topAnchor),
                    hostView.bottomAnchor.constraint(equalTo: bottomAnchor),
                    hostView.leadingAnchor.constraint(equalTo: leadingAnchor),
                    hostView.trailingAnchor.constraint(equalTo: trailingAnchor)
                ])
            }
        } else if let hostView = hostController?.view {
            hostView.removeFromSuperview()
        }
    }

    var content: Content? {
        didSet {
            update(with: content)
        }
    }
}

/**
 *  Table view cell hosting `SwiftUI` content.
 */
class HostTableViewCell<Content: View>: UITableViewCell {
    private var hostController: UIHostingController<HostCellView<Content>>?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        tintColor = .red
        backgroundColor = .clear

        let selectedBackgroundView = UIView()
        selectedBackgroundView.backgroundColor = .clear
        self.selectedBackgroundView = selectedBackgroundView
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func update(with content: Content?, editing: Bool, selected: Bool, selectionStyle: UITableViewCell.SelectionStyle, UIKitFocused: Bool) {
        if let content {
            let rootView = HostCellView(editing: editing, selected: selected && selectionStyle != .none, UIKitFocused: UIKitFocused, content: content)
            if let hostController {
                hostController.rootView = rootView
            } else {
                hostController = UIHostingController(rootView: rootView, ignoreSafeArea: true)
            }

            if let hostView = hostController?.view, hostView.superview != contentView {
                hostView.backgroundColor = .clear
                contentView.addSubview(hostView)

                hostView.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    hostView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: LayoutMargin),
                    hostView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
                    hostView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: LayoutMargin * 2),
                    hostView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -LayoutMargin * 2)
                ])
            }
        } else if let hostView = hostController?.view {
            hostView.removeFromSuperview()
        }
    }

    var content: Content? {
        didSet {
            update(with: content, editing: isEditing, selected: isSelected, selectionStyle: selectionStyle, UIKitFocused: isUIKitFocused)
        }
    }

    override var isEditing: Bool {
        didSet {
            update(with: content, editing: isEditing, selected: isSelected, selectionStyle: selectionStyle, UIKitFocused: isUIKitFocused)
        }
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        update(with: content, editing: isEditing, selected: isSelected, selectionStyle: selectionStyle, UIKitFocused: isUIKitFocused)
    }

    override var isSelected: Bool {
        didSet {
            update(with: content, editing: isEditing, selected: isSelected, selectionStyle: selectionStyle, UIKitFocused: isUIKitFocused)
        }
    }

    override var selectionStyle: UITableViewCell.SelectionStyle {
        didSet {
            update(with: content, editing: isEditing, selected: isSelected, selectionStyle: selectionStyle, UIKitFocused: isUIKitFocused)
        }
    }

    var isUIKitFocused = false {
        didSet {
            update(with: content, editing: isEditing, selected: isSelected, selectionStyle: selectionStyle, UIKitFocused: isUIKitFocused)
        }
    }
}

/**
 *  Table view view reusable view hosting `SwiftUI` content.
 */
class HostTableViewHeaderFooterView<Content: View>: UITableViewHeaderFooterView {
    private(set) var hostController: UIHostingController<Content>?

    private func update(with content: Content?) {
        if let rootView = content {
            if let hostController {
                hostController.rootView = rootView
            } else {
                hostController = UIHostingController(rootView: rootView, ignoreSafeArea: true)
            }

            if let hostView = hostController?.view, hostView.superview != self {
                hostView.backgroundColor = .clear
                addSubview(hostView)

                hostView.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    hostView.topAnchor.constraint(equalTo: topAnchor),
                    hostView.bottomAnchor.constraint(equalTo: bottomAnchor),
                    hostView.leadingAnchor.constraint(equalTo: leadingAnchor),
                    hostView.trailingAnchor.constraint(equalTo: trailingAnchor)
                ])
            }
        } else if let hostView = hostController?.view {
            hostView.removeFromSuperview()
        }
    }

    var content: Content? {
        didSet {
            update(with: content)
        }
    }
}

/**
 *  Simple view hosting `SwiftUI` content.
 */
class HostView<Content: View>: UIView {
    let ignoresSafeArea: Bool
    let topAnchorConstant: CGFloat
    let bottomAnchorConstant: CGFloat
    let leadingAnchorConstant: CGFloat
    let trailingAnchorConstant: CGFloat

    private var hostController: UIHostingController<Content>?

    init(frame: CGRect, ignoresSafeArea: Bool = true, topAnchorConstant: CGFloat = 0, bottomAnchorConstant: CGFloat = 0, leadingAnchorConstant: CGFloat = 0, trailingAnchorConstant: CGFloat = 0) {
        self.ignoresSafeArea = ignoresSafeArea
        self.topAnchorConstant = topAnchorConstant
        self.bottomAnchorConstant = bottomAnchorConstant
        self.leadingAnchorConstant = leadingAnchorConstant
        self.trailingAnchorConstant = trailingAnchorConstant
        super.init(frame: frame)
    }

    override convenience init(frame: CGRect) {
        self.init(frame: frame, ignoresSafeArea: true)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func update(with content: Content?) {
        if let rootView = content {
            if let hostController {
                hostController.rootView = rootView
            } else {
                hostController = UIHostingController(rootView: rootView, ignoreSafeArea: ignoresSafeArea)
            }

            if let hostView = hostController?.view, hostView.superview != self {
                hostView.backgroundColor = .clear
                addSubview(hostView)

                hostView.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    hostView.topAnchor.constraint(equalTo: topAnchor, constant: topAnchorConstant),
                    hostView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: bottomAnchorConstant),
                    hostView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: leadingAnchorConstant),
                    hostView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: trailingAnchorConstant)
                ])
            }
        } else if let hostView = hostController?.view {
            hostView.removeFromSuperview()
        }
    }

    var content: Content? {
        didSet {
            update(with: content)
        }
    }
}
