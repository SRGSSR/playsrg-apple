//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import Foundation
import SRGDataProvider

struct Service: Identifiable, Equatable {
    let id: String
    let name: String
    let url: URL

    private enum Id {
        static let production = "production"
        static let stage = "stage"
        static let test = "test"
        static let mmf = "play mmf"
        static let samProduction = "sam production"
        static let samStage = "sam stage"
        static let samTest = "sam test"
    }

    static var production = Self(
        id: Id.production,
        name: NSLocalizedString("Production", comment: "Server setting name"),
        url: SRGIntegrationLayerProductionServiceURL()
    )

    static var stage = Self(
        id: Id.stage,
        name: NSLocalizedString("Stage", comment: "Server setting name"),
        url: SRGIntegrationLayerStagingServiceURL()
    )

    static var test = Self(
        id: Id.test,
        name: NSLocalizedString("Test", comment: "Server setting name"),
        url: SRGIntegrationLayerTestServiceURL()
    )

    static var mmf = Self(
        id: Id.mmf,
        name: "Play MMF",
        url: mmfUrl
    )

    private static var mmfUrl: URL = {
        guard let mmfUrlString = Bundle.main.object(forInfoDictionaryKey: "PlayMMFServiceURL") as? String,
              !mmfUrlString.isEmpty
        else {
            return URL(string: "https://play-mmf.herokuapp.com")!
        }
        return URL(string: mmfUrlString)!
    }()

    static var samProduction = Self(
        id: Id.samProduction,
        name: "SAM \(NSLocalizedString("Production", comment: "Server setting name"))",
        url: SRGIntegrationLayerProductionServiceURL().appendingPathComponent("sam")
    )

    static var samStage = Self(
        id: Id.samStage,
        name: "SAM \(NSLocalizedString("Stage", comment: "Server setting name"))",
        url: SRGIntegrationLayerStagingServiceURL().appendingPathComponent("sam")
    )

    static var samTest = Self(
        id: Id.samTest,
        name: "SAM \(NSLocalizedString("Test", comment: "Server setting name"))",
        url: SRGIntegrationLayerTestServiceURL().appendingPathComponent("sam")
    )

    static var services: [Self] = [production, stage, test, mmf, samProduction, samStage, samTest]

    static func service(forId id: String?) -> Self {
        #if DEBUG || NIGHTLY || BETA
            guard let id, let server = services.first(where: { $0.id == id }) else {
                return .production
            }
            return server
        #else
            return .production
        #endif
    }
}

@objc class ServiceObjC: NSObject {
    @objc static var ids = Service.services.map(\.id)

    @objc static func name(forServiceId serviceId: String) -> String {
        Service.service(forId: serviceId).name
    }

    @objc static func url(forServiceId serviceId: String) -> URL {
        ApplicationConfiguration().serviceURL(forId: serviceId) ?? Service.service(forId: serviceId).url
    }
}
