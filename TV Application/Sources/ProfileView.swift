//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

struct ProfileView: View {
    private static let version: String = {
        let appVersion = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String
        let bundleNameSuffix = Bundle.main.infoDictionary!["BundleNameSuffix"] as! String
        let buildString = Bundle.main.infoDictionary!["CFBundleVersion"] as! String
        return String(format: "%@%@ (%@)", appVersion, bundleNameSuffix, buildString)
    }()
    
    var body: some View {
        VStack() {
            Spacer()
            Text("Profile")
            Spacer()
            Text(Self.version)
        }
    }
}
