//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGDataProviderCombine
import SRGNetwork

func friendlyMessage(for error: Error) -> String {
    if let error = error as? SRGDataProviderError {
        switch error {
        case let .http(statusCode):
            return HTTPURLResponse.srg_localizedString(forStatusCode: statusCode)
        case .invalidData:
            return NSLocalizedString("The data is invalid", comment: "Error message returned for invalid data")
        }
    }
    else {
        return error.localizedDescription
    }
}
