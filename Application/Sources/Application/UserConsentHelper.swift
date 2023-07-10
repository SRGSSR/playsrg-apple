//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGAppearance
import Usercentrics
import UsercentricsUI

@objc enum UCService: Int {
    case CommandersAct
    case FireBase
    case UserCentrics
}

@objc class UserConsentHelper: NSObject {
    // MARK: Notification names
    
    @objc static let userConsentWillShowBannerNotification = Notification.Name("UserConsentWillShowBannerNotification")
    @objc static let userConsentDidHideBannerNotification = Notification.Name("UserConsentHideBannerNotification")
    @objc static let userConsentDidChangeNotification = Notification.Name("UserConsentDidChangeNotification")
    
    @objc static let userConsentAcceptedCategoriesKey = "userConsentAcceptedCategories"
    
    // MARK: States
    
    static var isConfigured = false
    @objc static var isShowingBanner = false
    
    @objc static var acceptedCategories: [String] = [] {
        didSet {
            if oldValue != acceptedCategories {
                SRGAnalyticsTracker.shared.acceptedUserConsentCategories = acceptedCategories
                
                NotificationCenter.default.post(name: userConsentDidChangeNotification, object: nil, userInfo: [userConsentAcceptedCategoriesKey: acceptedCategories])
            }
        }
    }
    
    @objc static func hasConsentFor(service: UCService) -> Bool {
        if let consentForService = UsercentricsCore.shared.getConsents().first(where: { $0.templateId == serviceToTemplateIdMapping[service] }) {
            return consentForService.status
        }
        return false
    }
    
    private static let serviceToTemplateIdMapping: [UCService: String] = [
        UCService.CommandersAct: "1",
        UCService.FireBase: "2",
        UCService.UserCentrics: "3"
    ]
    
    private static var hasRunSetup = false
    private static var categoryToTemplateIdsMapping = [String: [String]]()
    
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
            categoryToTemplateIdsMapping = categoryToTemplateIdsMappingFromCMPData()
            acceptedCategories = acceptedCategories(acceptedServices: UsercentricsCore.shared.getConsents())
#if DEBUG || NIGHTLY || BETA
            if status.shouldCollectConsent || UserDefaults.standard.bool(forKey: PlaySRGSettingAlwaysAskUserConsentAtLaunchEnabled) {
                showFirstLayer()
            }
#else
            if status.shouldCollectConsent {
                showFirstLayer()
            }
#endif
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
            acceptedCategories = acceptedCategories(acceptedServices: response.consents)
            NotificationCenter.default.post(name: userConsentDidHideBannerNotification, object: nil)
        }
    }
    
    static func showSecondLayer() {
        isShowingBanner = true
        NotificationCenter.default.post(name: userConsentWillShowBannerNotification, object: nil)
        
        banner.showSecondLayer { response in
            isShowingBanner = false
            acceptedCategories = acceptedCategories(acceptedServices: response.consents)
            NotificationCenter.default.post(name: userConsentDidHideBannerNotification, object: nil)
        }
    }
    
    private static var banner: UsercentricsBanner {
        return UsercentricsBanner(bannerSettings: bannerSettings)
    }
    
#if os(iOS)
    private static func buttonSettings(denyVisible: Bool, isFirstLayer: Bool = false, color: UIColor?) -> [ButtonSettings] {
        var buttons: [ButtonSettings] = [ButtonSettings]()
        buttons.append(ButtonSettings(type: .acceptAll, backgroundColor: color))
        if denyVisible {
            buttons.append(ButtonSettings(type: .denyAll, backgroundColor: color))
        }
        
        buttons.append(isFirstLayer ? ButtonSettings(type: .more) : ButtonSettings(type: .save))
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
        
        let fl_settings = FirstLayerStyleSettings(buttonLayout: .column(buttons: buttonSettings(denyVisible: !firstLayerDenyHidden, isFirstLayer: true, color: primaryRedColor)),
                                                  backgroundColor: backgroundColor)
        
        let sl_settings = SecondLayerStyleSettings(buttonLayout: .column(buttons: buttonSettings(denyVisible: true, color: primaryRedColor)),
                                                   showCloseButton: nil)
        
        return BannerSettings(generalStyleSettings: settings, firstLayerStyleSettings: fl_settings, secondLayerStyleSettings: sl_settings, variantName: nil)
#else
        guard let logoImage = bannerLogoImage else { return nil }
        return BannerSettings(logo: logoImage)
#endif
    }
    
    private static func categoryToTemplateIdsMappingFromCMPData() -> [String: [String]] {
        var categoryToTemplateIdsMapping = [String: [String]]()
        
        let data = UsercentricsCore.shared.getCMPData(),
            categories = data.categories,
            services = data.services
        
        PlayLogDebug(category: "UserConsent", message: "Settings id: \(data.settings.settingsId)")
        PlayLogDebug(category: "UserConsent", message: "categorySlugs / label: \(categories.map({ "\($0.categorySlug) / \($0.label)" }))")
        
        for category in categories {
            categoryToTemplateIdsMapping[category.categorySlug] = services.filter({ $0.categorySlug == category.categorySlug }).compactMap({ $0.templateId })
        }
        
        return categoryToTemplateIdsMapping
    }
    
    private static func acceptedCategories(acceptedServices: [UsercentricsServiceConsent]) -> [String] {
        var acceptedCategories: [String] = [String]()
        for (categorySlug, services) in categoryToTemplateIdsMapping
        where acceptedServices.contains(where: { services.contains($0.templateId) && $0.status }) {
            acceptedCategories.append(categorySlug)
        }
        return acceptedCategories
    }
}
