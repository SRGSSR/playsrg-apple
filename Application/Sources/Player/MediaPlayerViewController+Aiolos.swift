//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import Foundation
import Aiolos

private var panelKey: Void?
private var coveredScrollViewKey: Void?

extension MediaPlayerViewController {
    
    static let contentHeight: CGFloat = 64.0

    @objc public func addSongPanel(channel: SRGChannel, coveredScrollView: UIScrollView?) {
        let songsViewStyle = ApplicationConfiguration.shared.channel(forUid: channel.uid)?.songsViewStyle ?? .none
        if songsViewStyle == .none { return }
        
        if let contentNavigationController = self.panel?.contentViewController as? UINavigationController {
            if let songsViewController = contentNavigationController.viewControllers.first as? SongsViewController {
                if songsViewController.channel == channel {
                    return
                }
            }
        }
        
        self.coveredScrollView = coveredScrollView
        
        if let coveredScrollView = coveredScrollView {
            let insets = UIEdgeInsets(top: 0.0, left: 0.0, bottom: MediaPlayerViewController.contentHeight, right: 0.0)
            coveredScrollView.contentInset = insets;
            coveredScrollView.scrollIndicatorInsets = insets;
        }
        
        let panel = makePanelController(channel: channel, mode: (songsViewStyle == .expanded) ? .expanded : .compact)
        panel.add(to: self)
        self.panel = panel
    }
    
    @objc public func removeSongPanel() {
        guard let panel = self.panel else { return }
        panel.removeFromParent(transition: .none, completion: nil)
        self.panel = nil
        
        if let coveredScrollView = self.coveredScrollView {
            coveredScrollView.contentInset = .zero
            coveredScrollView.scrollIndicatorInsets = .zero
        }
    }
    
    @objc public func updateSongPanel(for traitCollection: UITraitCollection, fullScreen: Bool) {
        guard let panel = self.panel else { return }
        
        if fullScreen {
            panel.removeFromParent(transition: .none, completion: nil)
        }
        else {
            panel.add(to: self)
            panel.performWithoutAnimation {
                panel.configuration = self.configuration(for: traitCollection, mode: panel.configuration.mode)
            }
        }
    }
    
    @objc public func reloadSongPanelSize() {
        guard let panel = self.panel else { return }
        panel.reloadSize()
    }
}

private extension MediaPlayerViewController {
    
    var coveredScrollView: UIScrollView? {
        get {
            return objc_getAssociatedObject(self, &coveredScrollViewKey) as? UIScrollView
        }
        set {
            objc_setAssociatedObject(self, &panelKey, coveredScrollViewKey, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    var panel: Panel? {
        get {
            return objc_getAssociatedObject(self, &panelKey) as? Panel
        }
        set {
            objc_setAssociatedObject(self, &panelKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    var compactHeight: CGFloat {
        get {
            return MediaPlayerViewController.contentHeight + self.view.safeAreaInsets.bottom
        }
    }
    
    func makePanelController(channel: SRGChannel, mode: Panel.Configuration.Mode) -> Panel {
        let songsViewController = SongsViewController(channel: channel)
        let contentNavigationController = NavigationController(rootViewController: songsViewController, tintColor: .white, backgroundColor: .play_cardGrayBackground, statusBarStyle: .default)
        
        let panelController = Panel(configuration: self.configuration(for: self.traitCollection, mode: mode))
        panelController.sizeDelegate = self
        panelController.resizeDelegate = self
        panelController.contentViewController = contentNavigationController
        
        return panelController
    }
    
    func configuration(for traitCollection: UITraitCollection, mode: Panel.Configuration.Mode) -> Panel.Configuration {
        var configuration = Panel.Configuration.default
        
        if traitCollection.userInterfaceIdiom == .pad && traitCollection.horizontalSizeClass == .regular {
            configuration.position = .leadingBottom
            configuration.positionLogic[.bottom] = .respectSafeArea
            configuration.margins = NSDirectionalEdgeInsets(top: 0.0, leading: 10.0, bottom: 0.0, trailing: 10.0)
        }
        else {
            configuration.position = .bottom;
            configuration.positionLogic[.bottom] = .ignoreSafeArea
            configuration.margins = .zero
        }
        
        configuration.supportedModes = [.compact, .expanded]
        configuration.mode = mode
        
        configuration.appearance.resizeHandle = .visible(foregroundColor: .white, backgroundColor: .play_cardGrayBackground)
        configuration.appearance.separatorColor = .clear
        configuration.appearance.borderColor = .clear
        
        return configuration
    }
}

extension MediaPlayerViewController : PanelSizeDelegate {
    
    public func panel(_ panel: Panel, sizeForMode mode: Panel.Configuration.Mode) -> CGSize {
        // Width ignored when for .bottom position, takes parent width
        let width: CGFloat = 400.0
        switch mode {
            case .compact:
                return CGSize(width: width, height: self.compactHeight)
            case .expanded:
                if let parent = panel.parent {
                    return CGSize(width: width, height: 0.45 * parent.view.frame.height)
                }
                else {
                    return CGSize(width: width, height: 400.0)
                }
            default:
                // Height hardcoded for other modes
                return CGSize(width: width, height: 0.0)
        }
    }
}

extension MediaPlayerViewController : PanelResizeDelegate {
    
    public func panelDidStartResizing(_ panel: Panel) {
        
    }
    
    public func panel(_ panel: Panel, willResizeTo size: CGSize) {
        guard let contentNavigationController = panel.contentViewController as? UINavigationController else { return }
        guard let songsViewController = contentNavigationController.viewControllers.first as? SongsViewController else { return }
        guard let tableView = songsViewController.tableView else { return }
        
        UIView.animate(withDuration: 0.1) {
            if size.height <= self.compactHeight {
                tableView.alpha = 0.0
            }
            else {
                tableView.alpha = 1.0
            }
        }
    }
    
    public func panel(_ panel: Panel, willTransitionFrom oldMode: Panel.Configuration.Mode?, to newMode: Panel.Configuration.Mode, with coordinator: PanelTransitionCoordinator) {
        
    }
}
