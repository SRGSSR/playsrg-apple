//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

struct ProfileView: View {
    private static let version: String = {
        let appVersion = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String
        let buildString = Bundle.main.infoDictionary!["CFBundleVersion"] as! String
        return String(format: "%@ (%@)", appVersion, buildString)
    }()
    
    var body: some View {
        VStack() {
            Spacer()
            Text("Profile")
            Spacer()
            Text("Version: \(Self.version)")
        }
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
    }
}
