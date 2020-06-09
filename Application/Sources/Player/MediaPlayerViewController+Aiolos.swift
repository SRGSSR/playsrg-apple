//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import Foundation
import Aiolos

private var panelKey: Void?

extension MediaPlayerViewController {

    @objc public func addSongPanel(channel: SRGChannel) {
        let songsViewStyle = ApplicationConfiguration.shared.channel(forUid: channel.uid)?.songsViewStyle ?? .none
        if songsViewStyle == .none { return }
        
        if let contentNavigationController = self.panel?.contentViewController as? UINavigationController {
            if let songsViewController = contentNavigationController.viewControllers.first as? SongsViewController {
                if songsViewController.channel == channel {
                    return
                }
            }
        }
        
        let panel = makePanelController(channel: channel, mode: (songsViewStyle == .expanded) ? .expanded : .compact)
        panel.add(to: self)
        self.panel = panel
    }
    
    @objc public func removeSongPanel() {
        guard let panel = self.panel else { return }
        panel.removeFromParent(transition: .none, completion: nil)
        self.panel = nil
    }
    
    @objc public func updatePanel(for traitCollection: UITraitCollection, fullScreen: Bool) {
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
            configuration.position = .trailingBottom
            configuration.positionLogic[.bottom] = .respectSafeArea
            configuration.margins = NSDirectionalEdgeInsets(top: 0.0, leading: 10.0, bottom: 0.0, trailing: 10.0)
        }
        else {
            configuration.position = .bottom;
            configuration.positionLogic[.bottom] = .ignoreSafeArea
            configuration.margins = .zero
        }
        
        configuration.supportedModes = [.compact, .expanded, .fullHeight]
        configuration.mode = mode
        
        configuration.appearance.resizeHandle = .visible(foregroundColor: .white, backgroundColor: .play_cardGrayBackground)
        configuration.appearance.separatorColor = .clear
        configuration.appearance.borderColor = .clear
        
        return configuration
    }
}

extension MediaPlayerViewController : PanelSizeDelegate {
    
    static let compactHeight: CGFloat = 80.0
    
    public func panel(_ panel: Panel, sizeForMode mode: Panel.Configuration.Mode) -> CGSize {
        // Width ignored when for .bottom position, takes parent width
        let width: CGFloat = 400.0
        switch mode {
            case .compact:
                return CGSize(width: width, height: MediaPlayerViewController.compactHeight)
            case .expanded:
                if let parent = panel.parent {
                    return CGSize(width: width, height: parent.view.frame.height / 3.0)
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
            if size.height <= MediaPlayerViewController.compactHeight {
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
