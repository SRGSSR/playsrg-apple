//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#if os(iOS)
import AirshipCore
#endif
import SRGAppearance
import Usercentrics
import UsercentricsUI

enum UCService: Hashable, CaseIterable {
#if os(iOS)
    case airship
#endif
    case appcenter
    case comscore
    case firebase
    case letterbox
    case tagcommander
    case usercentrics
    
    var templateId: String {
        switch self {
#if os(iOS)
        case .airship:
            return "hFLVABpNP"
#endif
        case .appcenter:
            return "XB0GBAmWEQ7Spr"
        case .comscore:
            return "B1WMgcNodi-7"
        case .firebase:
            return "2nEos-2ls"
        case .letterbox:
            return "TBD"
        case .tagcommander:
            return "ryi2qNjOsbX"
        case .usercentrics:
            return "H1Vl5NidjWX"
        }
    }
}

@objc class UserConsentHelper: NSObject {
    // MARK: Notification names
    
    @objc static let userConsentWillShowBannerNotification = Notification.Name("UserConsentWillShowBannerNotification")
    @objc static let userConsentDidHideBannerNotification = Notification.Name("UserConsentHideBannerNotification")
    @objc static let userConsentDidChangeNotification = Notification.Name("UserConsentDidChangeNotification")
    
    @objc static let userConsentServiceConsentsKey = "userConsentServiceConsents"
    
    // MARK: States
    
    @objc static var isConfigured = false
    @objc static var isShowingBanner = false
    
    @objc static func serviceConsents() -> [UsercentricsServiceConsent] {
        return UsercentricsCore.shared.getConsents()
    }
    
    private static var hasRunSetup = false
    
    private static func applyConsent(with serviceConsents: [UsercentricsServiceConsent]) {
        SRGAnalyticsTracker.shared.acceptedUserConsentServices = serviceConsents.filter({ $0.status == true }).map({ $0.templateId })
        
        for service in UCService.allCases {
            let serviceConsent = serviceConsents.first(where: { $0.templateId == service.templateId })
            let acceptedConsent = serviceConsent?.status ?? false
            
            switch service {
#if os(iOS)
            case .airship:
                // Airship analytics component is disabled at launch. See `PushService.m`.
                Airship.analytics.isComponentEnabled = acceptedConsent
#endif
            case .appcenter:
                // Only Crashes service is used. Not Analytics service.
                break
            case .comscore:
                // TODO: Inform SRGAnalytics
                break
            case .firebase:
                // IS_ANALYTICS_ENABLED is set to false in `GoogleService-Info-[BU].plist`.
                // TODO: Analytics.setAnalyticsCollectionEnabled(acceptedConsent) ?
                break
            case .letterbox:
                // TODO: Inform SRGLetterbox
                break
            case .tagcommander:
                // TODO: Inform SRGAnalytics
                break
            case .usercentrics:
                // Something to do?
                break
            }
        }
        
        NotificationCenter.default.post(name: userConsentDidChangeNotification, object: nil, userInfo: [userConsentServiceConsentsKey: serviceConsents])
#if DEBUG
        printServices()
#endif
    }
    
    // MARK: Setup
    
    @objc static func setup() {
        guard !hasRunSetup else { return }
        
        let options = UsercentricsOptions()
        if let ruleSetId = Bundle.main.object(forInfoDictionaryKey: "UserCentricsRuleSetId") as? String {
            options.ruleSetId = ruleSetId
        }
#if DEBUG
        options.loggerLevel = .debug
#endif
        UsercentricsCore.configure(options: options)
        
        UsercentricsCore.isReady { status in
            isConfigured = true
            
            var shouldCollectConsent = false
#if DEBUG || NIGHTLY || BETA
            shouldCollectConsent = status.shouldCollectConsent || UserDefaults.standard.bool(forKey: PlaySRGSettingAlwaysAskUserConsentAtLaunchEnabled)
#else
            shouldCollectConsent = status.shouldCollectConsent
#endif
            if shouldCollectConsent {
                showFirstLayer()
            }
            else {
                applyConsent(with: UsercentricsCore.shared.getConsents())
            }
        } onFailure: { error in
            PlayLogError(category: "UserCentrics", message: error.localizedDescription)
        }
        
        hasRunSetup = true
    }
    
    // MARK: Banners
    
    private static func showFirstLayer() {
        isShowingBanner = true
        NotificationCenter.default.post(name: userConsentWillShowBannerNotification, object: nil)
        
        banner.showFirstLayer { response in
            isShowingBanner = false
            applyConsent(with: response.consents)
            NotificationCenter.default.post(name: userConsentDidHideBannerNotification, object: nil)
        }
    }
    
    static func showSecondLayer() {
        isShowingBanner = true
        NotificationCenter.default.post(name: userConsentWillShowBannerNotification, object: nil)
        
        banner.showSecondLayer { response in
            isShowingBanner = false
            applyConsent(with: response.consents)
            NotificationCenter.default.post(name: userConsentDidHideBannerNotification, object: nil)
        }
    }
    
    private static var banner: UsercentricsBanner {
        return UsercentricsBanner(bannerSettings: bannerSettings)
    }
    
#if os(iOS)
    private static func buttonSettings(denyVisible: Bool, isFirstLayer: Bool = false, color: UIColor?) -> [ButtonSettings] {
        let cornerRadius: CGFloat = 8
        var buttons: [ButtonSettings] = [ButtonSettings]()
        buttons.append(ButtonSettings(type: .acceptAll, backgroundColor: color, cornerRadius: cornerRadius))
        if denyVisible {
            buttons.append(ButtonSettings(type: .denyAll, backgroundColor: color, cornerRadius: cornerRadius))
        }
        
        buttons.append(isFirstLayer ? ButtonSettings(type: .more, cornerRadius: cornerRadius) : ButtonSettings(type: .save, cornerRadius: cornerRadius))
        return buttons
    }
#endif
    
    private static var bannerLogoImage: UIImage? {
        return UIImage(named: "logo_bu_\(ApplicationConfiguration.shared.businessUnitIdentifier)")
    }
    
    private static var bannerSettings: BannerSettings? {
#if os(iOS)
        let backgroundColor = UIColor.srgGray23
        let textColor = UIColor.srgGrayC7
        let primaryRedColor = UIColor.srgRed
        
        var settings = GeneralStyleSettings()
        
        settings.layerBackgroundColor = backgroundColor
        settings.layerBackgroundSecondaryColor = backgroundColor
        settings.font = BannerFont(regularFont: SRGFont.font(.body), boldFont: SRGFont.font(.H3))
        settings.textColor = textColor
        settings.linkColor = textColor
        settings.links = LegalLinksSettings.hidden
        settings.toggleStyleSettings = ToggleStyleSettings(activeBackgroundColor: primaryRedColor,
                                                           inactiveBackgroundColor: UIColor.srgGray96,
                                                           disabledBackgroundColor: UIColor.srgGray33,
                                                           disabledThumbColor: UIColor.srgGray96)
        settings.tabColor = .white
        settings.logo = bannerLogoImage
        
        let cmpData = UsercentricsCore.shared.getCMPData()
        let firstLayerDenyHidden = cmpData.settings.firstLayer?.hideButtonDeny?.boolValue ?? true
        
        let firstLayerSettings = FirstLayerStyleSettings(buttonLayout: .column(buttons: buttonSettings(denyVisible: !firstLayerDenyHidden, isFirstLayer: true, color: primaryRedColor)),
                                                         backgroundColor: backgroundColor,
                                                         cornerRadius: 8)
        
        let secondLayerSettings = SecondLayerStyleSettings(buttonLayout: .column(buttons: buttonSettings(denyVisible: true, color: primaryRedColor)),
                                                           showCloseButton: nil)
        
        return BannerSettings(generalStyleSettings: settings,
                              firstLayerStyleSettings: firstLayerSettings,
                              secondLayerStyleSettings: secondLayerSettings,
                              variantName: nil)
#else
        guard let logoImage = bannerLogoImage else { return nil }
        return BannerSettings(logo: logoImage)
#endif
    }
    
#if DEBUG
    private static func printServices() {
        let data = UsercentricsCore.shared.getCMPData(),
            categories = data.categories,
            services = data.services
        
        PlayLogDebug(category: "UserConsent", message: "Settings id: \(data.settings.settingsId)")
        PlayLogDebug(category: "UserConsent", message: "categorySlug / label:\n\(categories.map({ "\($0.categorySlug) / \($0.label)" }).joined(separator: "\n"))")
        PlayLogDebug(category: "UserConsent", message: "templateId / dataProcessor:\n\(services.map({ "\($0.templateId ?? "null") / \($0.dataProcessor ?? "null")" }).joined(separator: "\n"))")
    }
#endif
}
