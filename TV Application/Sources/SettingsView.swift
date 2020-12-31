//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGIdentity
import SwiftUI

struct SettingsView: View {
    @State var isLoggedIn: Bool = false
    @State var account: SRGAccount?
    @State var displayLogoutAlert = false
    
    private static let version: String = {
        let appVersion = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String
        let bundleNameSuffix = Bundle.main.infoDictionary!["BundleNameSuffix"] as! String
        let buildName = Bundle.main.infoDictionary!["BuildName"] as! String
        let buildString = Bundle.main.infoDictionary!["CFBundleVersion"] as! String
        return String(format: "%@%@%@ (%@)", appVersion, bundleNameSuffix, buildName, buildString)
    }()
    
    private func refreshIdentityInformation() {
        isLoggedIn = (SRGIdentityService.current != nil) ? SRGIdentityService.current!.isLoggedIn : false
        account = SRGIdentityService.current?.account
    }
    
    var body: some View {
        VStack() {
            Spacer()
            if let identityService: SRGIdentityService = SRGIdentityService.current {
                if isLoggedIn {
                    let emailAddress = identityService.emailAddress
                    let accountDisplayName = account?.displayName
                    Text(accountDisplayName != nil ? accountDisplayName! : emailAddress != nil  ? emailAddress! : NSLocalizedString("My account", comment: "Text displayed when a user is logged in but no information has been retrieved yet"))
                }
                else {
                    Text(NSLocalizedString("Not logged in", comment: "Text displayed when no user is logged in"))
                }
                Button(action: {
                    if (isLoggedIn) {
                        self.displayLogoutAlert = true
                    }
                    else {
                        identityService.login(withEmailAddress: nil)
                    }
                }) {
                    Text(isLoggedIn ? NSLocalizedString("Logout", comment: "Logout button on Apple TV") : NSLocalizedString("Login", comment: "Login button on Apple TV"))
                }
                .padding()
                .alert(isPresented: $displayLogoutAlert) {
                    let primaryButton = Alert.Button.cancel(Text(NSLocalizedString("Cancel", comment: "Title of the cancel button in the alert view when logout"))) {}
                    let secondaryButton = Alert.Button.destructive(Text(NSLocalizedString("Logout", comment: "Logout button on Apple TV"))) {
                        identityService.logout()
                    }
                    return Alert(title: Text(NSLocalizedString("Logout", comment: "Logout alert view title on Apple TV")),
                                 message: Text(NSLocalizedString("Are you sure you want to logout?", comment: "Confirmation message displayed when the user is about to logout on Apple TV")),
                                 primaryButton: primaryButton,
                                 secondaryButton: secondaryButton)
                }
            }
            Spacer()
            Text(Self.version)
        }
        .onAppear {
            refreshIdentityInformation()
        }
        .onDisappear {
            
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name.SRGIdentityServiceUserDidCancelLogin, object: SRGIdentityService.current)) { notification in
            refreshIdentityInformation()
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name.SRGIdentityServiceUserDidLogin, object: SRGIdentityService.current)) { notification in
            refreshIdentityInformation()
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name.SRGIdentityServiceDidUpdateAccount, object: SRGIdentityService.current)) { notification in
            refreshIdentityInformation()
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name.SRGIdentityServiceUserDidLogout, object: SRGIdentityService.current)) { notification in
            refreshIdentityInformation()
        }
    }
}
