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
    case srgsnitch
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
        case .srgsnitch:
            return "OJxjJSgHYThNaE"
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
    
    private(set) static var isConfigured = false
    @objc private(set) static var isShowingBanner = false
    
    static func serviceConsents() -> [UsercentricsServiceConsent] {
        return UsercentricsCore.shared.getConsents()
    }
    
    // Retain potiential collecting consent banner to be displayed as modal on top of each views.
    // Don't forget to call `waitCollectingConsentRelease()` when the blocking condition is over.
    @objc static func waitCollectingConsentRetain() {
        waitCollectingConsentPool += 1
    }
    
    // Release waiting pool to allow to display collecting consent banner as modal on top of each views, if any.
    @objc static func waitCollectingConsentRelease() {
        guard waitCollectingConsentPool > 0 else { return }
        
        waitCollectingConsentPool -= 1
        
        if waitCollectingConsentPool == 0 && shouldCollectConsent {
            shouldCollectConsent = false
            
            // Dispatch on next main thread loop, with a tiny delay.
            DispatchQueue.global(qos: .userInteractive).asyncAfter(deadline: .now() + DispatchTimeInterval.seconds(1)) {
                showFirstLayer()
            }
        }
    }
    
    private static var hasRunSetup = false
    
    private static var waitCollectingConsentPool: UInt = 0
    private static var shouldCollectConsent = false
    
    static var acceptedServiceIds: [String] {
        get {
            return UserDefaults.standard.stringArray(forKey: PlaySRGSettingUserConsentAcceptedServiceIds) ?? []
        }
        set {
            UserDefaults.standard.set(newValue, forKey: PlaySRGSettingUserConsentAcceptedServiceIds)
        }
    }
    
    // MARK: Setup
    
    @objc static func setup() {
        guard !hasRunSetup else { return }
        
        configureAndApplyConsents()
        
        hasRunSetup = true
    }
    
    private static func configureAndApplyConsents() {
        let options = UsercentricsOptions()
        let ruleSetIdKey = ApplicationConfiguration.shared.isUserConsentCentralizedRuleSetPreferred ? "UserCentricsSRGRuleSetId" : "UserCentricsRuleSetId"
        if let ruleSetId = Bundle.main.object(forInfoDictionaryKey: ruleSetIdKey) as? String {
            options.ruleSetId = ruleSetId
            
            if let defaultLanguage = ApplicationConfiguration.shared.userConsentDefaultLanguage {
                options.defaultLanguage = defaultLanguage
            }
        }
#if DEBUG
        options.loggerLevel = .debug
#endif
        UsercentricsCore.configure(options: options)
        
        applyConsent(with: acceptedServiceIds)
        
        UsercentricsCore.isReady { status in
            isConfigured = true
            
#if DEBUG || NIGHTLY || BETA
            shouldCollectConsent = status.shouldCollectConsent || UserDefaults.standard.bool(forKey: PlaySRGSettingAlwaysAskUserConsentAtLaunchEnabled)
#else
            shouldCollectConsent = status.shouldCollectConsent
#endif
            if shouldCollectConsent && waitCollectingConsentPool == 0 {
                shouldCollectConsent = false
                showFirstLayer()
            }
            else {
                applyConsent(with: UsercentricsCore.shared.getConsents())
            }
        } onFailure: { error in
            PlayLogError(category: "UserCentrics", message: error.localizedDescription)
        }
    }
    
    // MARK: Banners
    
    private static func showFirstLayer() {
        guard let mainTopViewController = UIApplication.shared.mainTopViewController else { return }
        
        isShowingBanner = true
        NotificationCenter.default.post(name: userConsentWillShowBannerNotification, object: nil)
        
        banner.showFirstLayer(hostView: mainTopViewController) { response in
            isShowingBanner = false
            applyConsent(with: response.consents)
            NotificationCenter.default.post(name: userConsentDidHideBannerNotification, object: nil)
        }
    }
    
    static func showSecondLayer() {
        guard let mainTopViewController = UIApplication.shared.mainTopViewController else { return }
        
        isShowingBanner = true
        NotificationCenter.default.post(name: userConsentWillShowBannerNotification, object: nil)
        
        banner.showSecondLayer(hostView: mainTopViewController) { response in
            isShowingBanner = false
            applyConsent(with: response.consents)
            NotificationCenter.default.post(name: userConsentDidHideBannerNotification, object: nil)
        }
    }
    
    private static var banner: UsercentricsBanner {
        return UsercentricsBanner(bannerSettings: bannerSettings)
    }
    
    private static var bannerLogoImage: UIImage? {
        return UIImage(named: "logo_bu_\(ApplicationConfiguration.shared.businessUnitIdentifier)")
    }
    
    private static var bannerSettings: BannerSettings? {
#if os(iOS)
        let backgroundColor = UIColor.srgGray23
        let foregroundColor = UIColor.white
        let textColor = UIColor.srgGrayC7
        
        var settings = GeneralStyleSettings()
        
        settings.layerBackgroundColor = backgroundColor
        settings.layerBackgroundSecondaryColor = backgroundColor
        settings.font = BannerFont(regularFont: SRGFont.font(.body), boldFont: SRGFont.font(.H3))
        settings.textColor = textColor
        settings.linkColor = textColor
        settings.links = LegalLinksSettings.hidden
        settings.toggleStyleSettings = ToggleStyleSettings(activeBackgroundColor: .srgRed,
                                                           inactiveBackgroundColor: .srgGray96,
                                                           disabledBackgroundColor: .srgGray33,
                                                           activeThumbColor: .white,
                                                           inactiveThumbColor: .white,
                                                           disabledThumbColor: .srgGray96)
        settings.tabColor = foregroundColor
        settings.bordersColor = foregroundColor
        settings.logo = bannerLogoImage
        
        let cmpData = UsercentricsCore.shared.getCMPData()
        
        let firstLayerSettings = FirstLayerStyleSettings(buttonLayout: .column(buttons: firstLayerButtonSettings(cmpData: cmpData)),
                                                         backgroundColor: backgroundColor,
                                                         cornerRadius: 8)
        
        let secondLayerSettings = SecondLayerStyleSettings(buttonLayout: .column(buttons: secondLayerButtonSettings(cmpData: cmpData)),
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
    
#if os(iOS)
    private static func firstLayerButtonSettings(cmpData: UsercentricsCMPData) -> [ButtonSettings] {
        var buttons: [ButtonSettings] = [ButtonSettings]()
        buttons.append(button(type: .acceptAll, isPrimary: true))
        if !(cmpData.settings.firstLayer?.hideButtonDeny?.boolValue ?? false) {
            buttons.append(button(type: .denyAll, isPrimary: true))
        }
        buttons.append(button(type: .more, isPrimary: false))
        return buttons
    }
    
    private static func secondLayerButtonSettings(cmpData: UsercentricsCMPData) -> [ButtonSettings] {
        var buttons: [ButtonSettings] = [ButtonSettings]()
        buttons.append(button(type: .acceptAll, isPrimary: false))
        if !(cmpData.settings.secondLayer.hideButtonDeny?.boolValue ?? false) {
            buttons.append(button(type: .denyAll, isPrimary: false))
        }
        buttons.append(button(type: .save, isPrimary: true))
        return buttons
    }
    
    private static func button(type: UsercentricsUI.ButtonType, isPrimary: Bool) -> ButtonSettings {
        return ButtonSettings(type: type,
                              textColor: isPrimary ? .white : .srgGray23,
                              backgroundColor: isPrimary ? .srgRed : .srgGrayC7,
                              cornerRadius: 8)
    }
#endif
    
    // MARK: Apply consent
    
    private static func applyConsent(with serviceConsents: [UsercentricsServiceConsent]) {
        applyConsent(with: serviceConsents.filter({ $0.status == true }).map({ $0.templateId }))
        
        NotificationCenter.default.post(name: userConsentDidChangeNotification, object: nil, userInfo: [userConsentServiceConsentsKey: serviceConsents])
#if DEBUG
        printServices()
#endif
    }
    
    private static func applyConsent(with acceptedUserConsentServices: [String]) {
        acceptedServiceIds = acceptedUserConsentServices
        SRGAnalyticsTracker.shared.consentedServices = acceptedUserConsentServices
        
        for service in UCService.allCases {
            let acceptedUserConsentService = acceptedUserConsentServices.first(where: { $0 == service.templateId })
            let acceptedConsent = (acceptedUserConsentService != nil) ? true : false
            
            switch service {
#if os(iOS)
            case .airship:
                // Airship analytics feature is disabled at launch. See `PushService.m`.
                if acceptedConsent {
                    Airship.shared.privacyManager.enableFeatures(Features.analytics)
                }
                else {
                    Airship.shared.privacyManager.disableFeatures(Features.analytics)
                }
#endif
            case .appcenter:
                // Only `Crashes` service is used. `Analytics` service not instantiated.
                // `AppCenterAnalytics` framework not imported.
                break
            case .comscore:
                // TODO: Inform SRGAnalytics
                break
            case .firebase:
                // IS_ANALYTICS_ENABLED is set to false in `GoogleService-Info-[BU].plist`.
                // `FirebaseAnalytics` framework not imported.
                break
            case .srgsnitch:
                // TODO: Inform SRGLetterbox
                break
            case .tagcommander:
                // TODO: Inform SRGAnalytics
                break
            case .usercentrics:
                // Always essential. No settings available in the framework.
                break
            }
        }
        
#if DEBUG
        printApplyConsent()
#endif
    }
    
#if DEBUG
    
    // MARK: Debug
    
    private static func printServices() {
        let data = UsercentricsCore.shared.getCMPData(),
            categories = data.categories,
            services = data.services
        
        PlayLogDebug(category: "UserConsent", message: "Settings id: \(data.settings.settingsId)")
        PlayLogDebug(category: "UserConsent", message: "categorySlug / label:\n\(categories.map({ "\($0.categorySlug) / \($0.label)" }).joined(separator: "\n"))")
        PlayLogDebug(category: "UserConsent", message: "templateId / dataProcessor:\n\(services.map({ "\($0.templateId ?? "null") / \($0.dataProcessor ?? "null")" }).joined(separator: "\n"))")
    }
    
    private static func printApplyConsent() {
        PlayLogDebug(category: "UserConsent", message: "Accepted templateIds:\n\(acceptedServiceIds.joined(separator: "\n"))")
    }
#endif
}
