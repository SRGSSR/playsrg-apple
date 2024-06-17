//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import CarPlay

// MARK: Protocols

protocol CarPlayTemplateController {
    func willAppear(animated: Bool)
    func didAppear(animated: Bool)
    func willDisappear(animated: Bool)
    func didDisappear(animated: Bool)
}

protocol CarPlayTemplateContainer {
    var activeChildTemplate: CPTemplate? { get }
}

// MARK: Extensions

private var controllerKey: Void?
private var appearedOnceKey: Void?

extension CPTemplate {
    /**
     *  Associate a controller object to the template, with matching lifetime.
     */
    var controller: CarPlayTemplateController? {
        get {
            objc_getAssociatedObject(self, &controllerKey) as? CarPlayTemplateController
        }
        set {
            objc_setAssociatedObject(self, &controllerKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    private var appearedOnce: Bool {
        get {
            objc_getAssociatedObject(self, &appearedOnceKey) as? Bool ?? false
        }
        set {
            objc_setAssociatedObject(self, &appearedOnceKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    func notifyWillAppear(animated: Bool) {
        notifyWillAppear(animated: animated, recursive: false)
    }

    func notifyDidAppear(animated: Bool) {
        notifyDidAppear(animated: animated, recursive: false)
    }

    func notifyWillDisappear(animated: Bool) {
        notifyWillDisappear(animated: animated, recursive: false)
    }

    func notifyDidDisappear(animated: Bool) {
        notifyDidDisappear(animated: animated, recursive: false)
    }

    private func notifyWillAppear(animated: Bool, recursive: Bool) {
        if recursive, let container = self as? CarPlayTemplateContainer, let activeChildTemplate = container.activeChildTemplate {
            activeChildTemplate.notifyWillAppear(animated: animated, recursive: recursive)
        }

        if !recursive || appearedOnce {
            controller?.willAppear(animated: animated)
        }
    }

    private func notifyDidAppear(animated: Bool, recursive: Bool) {
        if recursive, let container = self as? CarPlayTemplateContainer, let activeChildTemplate = container.activeChildTemplate {
            activeChildTemplate.notifyDidAppear(animated: animated, recursive: recursive)
        }

        if !recursive || appearedOnce {
            controller?.didAppear(animated: animated)
        }

        appearedOnce = true
    }

    private func notifyWillDisappear(animated: Bool, recursive: Bool) {
        if recursive, let container = self as? CarPlayTemplateContainer, let activeChildTemplate = container.activeChildTemplate {
            activeChildTemplate.notifyWillDisappear(animated: animated, recursive: recursive)
        }
        controller?.willDisappear(animated: animated)
    }

    private func notifyDidDisappear(animated: Bool, recursive: Bool) {
        if recursive, let container = self as? CarPlayTemplateContainer, let activeChildTemplate = container.activeChildTemplate {
            activeChildTemplate.notifyDidDisappear(animated: animated, recursive: recursive)
        }
        controller?.didDisappear(animated: animated)
    }
}

extension CPTabBarTemplate: CarPlayTemplateContainer {
    var activeChildTemplate: CPTemplate? {
        selectedTemplate
    }
}
