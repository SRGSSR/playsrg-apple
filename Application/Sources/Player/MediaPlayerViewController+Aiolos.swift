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
        if let contentNavigationController = self.panel?.contentViewController as? UINavigationController {
            if let songsViewController = contentNavigationController.viewControllers.first as? SongsViewController {
                if songsViewController.channel == channel {
                    return
                }
            }
        }
        
        let panel = makePanelController(channel: channel)
        panel.add(to: self)
        self.panel = panel
    }
    
    @objc public func removeSongPanel() {
        guard let panel = self.panel else { return }
        panel.removeFromParent(transition: .none, completion: nil)
    }
    
    @objc public func updatePanel(for traitCollection: UITraitCollection) {
        guard let panel = self.panel else { return }
        panel.performWithoutAnimation {
            panel.configuration = self.configuration(for: traitCollection)
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
    
    func makePanelController(channel: SRGChannel) -> Panel {
        let songsViewController = SongsViewController(channel: channel)
        let contentNavigationController = NavigationController(rootViewController: songsViewController, tintColor: .white, backgroundColor: .play_cardGrayBackground, statusBarStyle: .default)
        
        let panelController = Panel(configuration: self.configuration(for: self.traitCollection))
        panelController.sizeDelegate = self
        panelController.contentViewController = contentNavigationController
        
        return panelController
    }
    
    func configuration(for traitCollection: UITraitCollection) -> Panel.Configuration {
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
        
        configuration.appearance.resizeHandle = .visible(foregroundColor: .white, backgroundColor: .play_cardGrayBackground)
        configuration.appearance.separatorColor = .clear
        configuration.appearance.borderColor = .clear
        
        return configuration
    }
}

extension MediaPlayerViewController : PanelSizeDelegate {
    
    public func panel(_ panel: Panel, sizeForMode mode: Panel.Configuration.Mode) -> CGSize {
        // Width ignored when for .bottom position, takes parent width
        let width = 400.0
        switch mode {
            case .compact:
                return CGSize(width: width, height: 80.0)
            case .expanded:
                return CGSize(width: width, height: 400.0)
            default:
                // Height hardcoded for other modes
                return CGSize(width: width, height: 0.0)
        }
    }
}
