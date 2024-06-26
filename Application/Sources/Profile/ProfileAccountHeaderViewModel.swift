//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import Combine
import SRGIdentity

// MARK: View model

final class ProfileAccountHeaderViewModel: ObservableObject {
    @Published var data: Data

    func manageAccount() {
        guard let identityService = SRGIdentityService.current else { return }

        if identityService.isLoggedIn {
            identityService.showAccountView()
        } else {
            let lastLoggedInEmailAddress = UserDefaults.standard.string(forKey: PlaySRGSettingLastLoggedInEmailAddress)
            if identityService.login(withEmailAddress: lastLoggedInEmailAddress) {
                AnalyticsEvent.identity(action: .displayLogin).send()
            }
        }
    }

    init() {
        guard let identityService = SRGIdentityService.current else { data = .notLogged; return }

        data = Data(isLoggedIn: identityService.isLoggedIn, account: identityService.account)

        Publishers.Merge3(
            NotificationCenter.default.weakPublisher(for: .SRGIdentityServiceUserDidLogin, object: identityService),
            NotificationCenter.default.weakPublisher(for: .SRGIdentityServiceDidUpdateAccount, object: identityService),
            NotificationCenter.default.weakPublisher(for: .SRGIdentityServiceUserDidLogout, object: identityService)
        )
        .throttle(for: 0.5, scheduler: DispatchQueue.main, latest: true)
        .map { _ in
            Data(isLoggedIn: identityService.isLoggedIn, account: identityService.account)
        }
        .removeDuplicates()
        .assign(to: &$data)
    }
}

// MARK: Accessibility

extension ProfileAccountHeaderViewModel {
    var accessibilityLabel: String {
        if let accountDescription = data.accountDescription {
            String(format: PlaySRGAccessibilityLocalizedString("Logged in user: %@", comment: "Accessibility introductory text for the logged in user"), accountDescription)
        } else {
            data.text
        }
    }

    var accessibilityHint: String {
        data.isLoggedIn ?
            PlaySRGAccessibilityLocalizedString("Manages account information", comment: "Accessibility hint for the profile header when user is logged in") :
            PlaySRGAccessibilityLocalizedString("allows to log in or create an account in order to synchronize data.", comment: "Accessibility hint for the profile header when user is not logged in")
    }
}

// MARK: Types

extension ProfileAccountHeaderViewModel {
    /// Input data for the model
    struct Data: Hashable {
        let isLoggedIn: Bool
        let account: SRGAccount?

        var icon: ImageResource {
            isLoggedIn ? .accountLoggedInIcon : .accountLoggedOutIcon
        }

        var accountDescription: String? {
            guard isLoggedIn else { return nil }
            if let displayName = account?.displayName {
                return displayName
            } else if let emmailAddress = account?.emailAddress {
                return emmailAddress
            } else {
                return nil
            }
        }

        var text: String {
            if isLoggedIn {
                if let accountDescription {
                    accountDescription
                } else {
                    NSLocalizedString("My account", comment: "Text displayed when a user is logged in but no information has been retrieved yet")
                }
            } else {
                NSLocalizedString("Sign in", comment: "Text displayed within the sign in profile header when no user is logged in")
            }
        }

        static var notLogged = Self(isLoggedIn: false, account: nil)
    }
}
