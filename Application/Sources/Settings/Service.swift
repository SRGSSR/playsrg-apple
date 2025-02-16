//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import Foundation

enum Service: String, Identifiable, CaseIterable {
    case production
    case stage
    case test
    case mmf = "play mmf"
    case samProduction = "sam production"
    case samStage = "sam stage"
    case samTest = "sam test"

    private static var mmfUrl: URL {
        guard let mmfUrlString = Bundle.main.object(forInfoDictionaryKey: "PlayMMFServiceURL") as? String,
              !mmfUrlString.isEmpty
        else {
            return URL(string: "https://play-mmf.herokuapp.com")!
        }
        return URL(string: mmfUrlString)!
    }

    var id: Self {
        self
    }

    var environment: String {
        rawValue
    }

    var name: String {
        switch self {
        case .production:
            NSLocalizedString("Production", comment: "Server setting name")
        case .stage:
            NSLocalizedString("Stage", comment: "Server setting name")
        case .test:
            NSLocalizedString("Test", comment: "Server setting name")
        case .mmf:
            "Play MMF"
        case .samProduction:
            "SAM \(NSLocalizedString("Production", comment: "Server setting name"))"
        case .samStage:
            "SAM \(NSLocalizedString("Stage", comment: "Server setting name"))"
        case .samTest:
            "SAM \(NSLocalizedString("Test", comment: "Server setting name"))"
        }
    }

    var url: URL {
        switch self {
        case .production:
            ApplicationConfiguration().dataProviderProductionServiceURL
        case .stage:
            ApplicationConfiguration().dataProviderStageServiceURL
        case .test:
            ApplicationConfiguration().dataProviderTestServiceURL
        case .mmf:
            Self.mmfUrl
        case .samProduction:
            ApplicationConfiguration().dataProviderProductionServiceURL.appendingPathComponent("sam")
        case .samStage:
            ApplicationConfiguration().dataProviderStageServiceURL.appendingPathComponent("sam")
        case .samTest:
            ApplicationConfiguration().dataProviderTestServiceURL.appendingPathComponent("sam")
        }
    }

    static func service(for environment: String?) -> Self {
        #if DEBUG || NIGHTLY || BETA
            guard let environment, let service = Self(rawValue: environment) else {
                return .production
            }
            return service
        #else
            return .production
        #endif
    }
}

@objc class ServiceObjC: NSObject {
    @objc static var environments = Service.allCases.map(\.environment)

    @objc static func name(for environment: String) -> String {
        Service.service(for: environment).name
    }

    @objc static func url(for environment: String) -> URL {
        Service.service(for: environment).url
    }
}
