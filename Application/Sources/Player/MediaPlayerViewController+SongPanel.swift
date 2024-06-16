//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import Aiolos
import Foundation
import SRGAppearanceSwift

private var panelKey: Void?
private var tapGestureRecognizerKey: Void?

extension MediaPlayerViewController {
    static let contentHeight: CGFloat = 64.0

    @objc func addSongPanel(channel: SRGChannel) {
        guard let songsViewStyle = ApplicationConfiguration.shared.channel(forUid: channel.uid)?.songsViewStyle, songsViewStyle != .none else { return }

        if let contentNavigationController = panel?.contentViewController as? UINavigationController,
           let songsViewController = contentNavigationController.viewControllers.first as? SongsViewController {
            if songsViewController.channel == channel {
                return
            } else {
                removeSongPanel()
            }
        }

        if let programsTableView {
            let insets = UIEdgeInsets(top: 0.0, left: 0.0, bottom: MediaPlayerViewController.contentHeight, right: 0.0)
            programsTableView.contentInset = insets
            programsTableView.scrollIndicatorInsets = insets
        }

        let collapsed = (songsViewStyle == .collapsed)
        let panel = makePanelController(channel: channel, mode: collapsed ? .compact : .expanded)
        panel.add(to: self)
        self.panel = panel

        updateSongTableVisibility(hidden: collapsed, animated: false)
    }

    @objc func removeSongPanel() {
        guard let panel else { return }
        panel.removeFromParent(transition: .none, completion: nil)
        self.panel = nil

        if let programsTableView {
            programsTableView.contentInset = .zero
            programsTableView.scrollIndicatorInsets = .zero
        }
    }

    @objc func updateSongPanel(for traitCollection: UITraitCollection, fullScreen: Bool) {
        guard let panel else { return }

        if fullScreen {
            panel.removeFromParent(transition: .none, completion: nil)
        } else {
            panel.add(to: self)
            panel.performWithoutAnimation {
                panel.configuration = configuration(for: traitCollection, mode: panel.configuration.mode)
            }
        }
    }

    @objc func reloadSongPanelSize() {
        guard let panel else { return }
        panel.reloadSize()
    }

    @objc func scrollToSong(at date: Date?, animated: Bool) {
        guard let songsViewController else { return }
        songsViewController.scrollToSong(at: date, animated: animated)
    }

    @objc func updateSelectionForSong(at date: Date?) {
        guard let songsViewController else { return }
        songsViewController.updateSelectionForSong(at: date)
    }

    @objc func updateSelectionForCurrentSong() {
        guard let songsViewController else { return }
        songsViewController.updateSelectionForCurrentSong()
    }

    @objc func updateSongProgress() {
        guard let songsViewController else { return }
        songsViewController.updateProgress(for: letterboxController.play_dateInterval)
    }
}

private extension MediaPlayerViewController {
    var panel: Panel? {
        get {
            return objc_getAssociatedObject(self, &panelKey) as? Panel
        }
        set {
            objc_setAssociatedObject(self, &panelKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    var tapGestureRecognizer: UITapGestureRecognizer? {
        get {
            return objc_getAssociatedObject(self, &tapGestureRecognizerKey) as? UITapGestureRecognizer
        }
        set {
            objc_setAssociatedObject(self, &tapGestureRecognizerKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    var compactHeight: CGFloat {
        if let window = UIApplication.shared.mainWindow {
            return MediaPlayerViewController.contentHeight + window.safeAreaInsets.bottom
        } else {
            return MediaPlayerViewController.contentHeight
        }
    }

    var songsViewController: SongsViewController? {
        guard let panel else { return nil }
        guard let contentNavigationController = panel.contentViewController as? UINavigationController else { return nil }
        return contentNavigationController.viewControllers.first as? SongsViewController
    }

    func makePanelController(channel: SRGChannel, mode: Panel.Configuration.Mode) -> Panel {
        let songsViewController = SongsViewController(channel: channel, letterboxController: letterboxController)
        let contentNavigationController = NavigationController(rootViewController: songsViewController, tintColor: .white,
                                                               backgroundColor: .srgGray23, statusBarStyle: .default)

        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(togglePanel(_:)))
        contentNavigationController.navigationBar.addGestureRecognizer(tapGestureRecognizer)
        self.tapGestureRecognizer = tapGestureRecognizer

        let panelController = Panel(configuration: configuration(for: traitCollection, mode: mode))
        panelController.sizeDelegate = self
        panelController.resizeDelegate = self
        panelController.accessibilityDelegate = self
        panelController.contentViewController = contentNavigationController

        return panelController
    }

    func configuration(for traitCollection: UITraitCollection, mode: Panel.Configuration.Mode) -> Panel.Configuration {
        var configuration = Panel.Configuration.default

        if traitCollection.userInterfaceIdiom == .pad && traitCollection.horizontalSizeClass == .regular {
            configuration.position = .leadingBottom
            configuration.positionLogic[.bottom] = .respectSafeArea
            configuration.margins = NSDirectionalEdgeInsets(top: 0.0, leading: 10.0, bottom: 0.0, trailing: 10.0)
        } else {
            configuration.position = .bottom
            configuration.positionLogic[.bottom] = .ignoreSafeArea
            configuration.margins = .zero
        }

        configuration.supportedModes = [.compact, .expanded, .fullHeight]
        configuration.mode = mode

        configuration.appearance.resizeHandle = .visible(foregroundColor: .srgGrayD2, backgroundColor: .srgGray23)
        configuration.appearance.separatorColor = .clear
        configuration.appearance.borderColor = .clear

        return configuration
    }

    func songTableView() -> UITableView? {
        guard let songsViewController else { return nil }
        return songsViewController.tableView
    }

    func updateSongTableVisibility(hidden: Bool, animated: Bool) {
        guard let tableView = songTableView() else { return }

        let animations: () -> Void = {
            tableView.alpha = hidden ? 0.0 : 1.0
        }

        if animated {
            UIView.animate(withDuration: 0.1, animations: animations)
        } else {
            animations()
        }
    }

    @objc func togglePanel(_: UITapGestureRecognizer) {
        guard let panel else { return }

        switch panel.configuration.mode {
        case .compact:
            panel.configuration.mode = .expanded
        case .expanded:
            panel.configuration.mode = .compact
        case .fullHeight:
            panel.configuration.mode = .expanded
        default:
            break
        }
    }
}

extension MediaPlayerViewController: PanelSizeDelegate {
    public func panel(_ panel: Panel, sizeForMode mode: Panel.Configuration.Mode) -> CGSize {
        // Width ignored when for .bottom position, takes parent width
        let width: CGFloat = 400.0
        switch mode {
        case .compact:
            return CGSize(width: width, height: compactHeight)
        case .expanded:
            if let parent = panel.parent {
                return CGSize(width: width, height: 0.45 * parent.view.frame.height)
            } else {
                return CGSize(width: width, height: 400.0)
            }
        default:
            // Height hardcoded for other modes
            return CGSize(width: width, height: 0.0)
        }
    }
}

extension MediaPlayerViewController: PanelResizeDelegate {
    public func panelDidStartResizing(_: Panel) {
        // Trick to avoid the tap gesture triggered at the same time as the resizing one for small finger movements.
        tapGestureRecognizer?.isEnabled = false
        DispatchQueue.main.async {
            self.tapGestureRecognizer?.isEnabled = true
        }
    }

    public func panel(_: Panel, willResizeTo size: CGSize) {
        let hidden = (size.height <= compactHeight)
        updateSongTableVisibility(hidden: hidden, animated: true)
    }

    public func panel(_: Panel, willTransitionFrom oldMode: Panel.Configuration.Mode?, to _: Panel.Configuration.Mode, with coordinator: PanelTransitionCoordinator) {
        if let tableView = songTableView() {
            coordinator.animateAlongsideTransition({
                if oldMode == .compact {
                    UIView.performWithoutAnimation {
                        self.scrollToSong(at: self.letterboxController.currentDate, animated: false)
                    }
                }
            }) { _ in
                tableView.flashScrollIndicators()
            }
        }
    }
}

extension MediaPlayerViewController: PanelAccessibilityDelegate {
    public func panel(_ panel: Panel, accessibilityLabelForResizeHandle _: ResizeHandle) -> String {
        if panel.configuration.mode == .compact {
            return PlaySRGAccessibilityLocalizedString("Show music list", comment: "Accessibility label of the song list handle when closed")
        } else {
            return PlaySRGAccessibilityLocalizedString("Hide music list", comment: "Accessibility label of the song list handle when opened")
        }
    }

    public func panel(_ panel: Panel, didActivateResizeHandle _: ResizeHandle) -> Bool {
        switch panel.configuration.mode {
        case .compact:
            panel.configuration.mode = .expanded
        case .expanded, .fullHeight:
            panel.configuration.mode = .compact
        default:
            break
        }
        return true
    }
}
