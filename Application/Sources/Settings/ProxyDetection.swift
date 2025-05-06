//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import Foundation

enum ProxyDetection: String, CaseIterable, Identifiable {
    case `default` = ""
    case VPNORPROXY
    case DIRECT

    var id: Self {
        self
    }

    var description: String {
        switch self {
        case .VPNORPROXY:
            NSLocalizedString("Via a VPN or Proxy", comment: "VPN or Proxy detection setting state")
        case .DIRECT:
            NSLocalizedString("Direct connection", comment: "VPN or Proxy detection setting state")
        case .default:
            NSLocalizedString("Default (IP-based detection)", comment: "VPN or Proxy detection setting state")
        }
    }
}
