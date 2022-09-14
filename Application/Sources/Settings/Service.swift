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
    
    static var production = Service(
        id: "production",
        name: NSLocalizedString("Production", comment: "Server setting name"),
        url: SRGIntegrationLayerProductionServiceURL()
    )
    
    static var stage = Service(
        id: "stage",
        name: NSLocalizedString("Stage", comment: "Server setting name"),
        url: SRGIntegrationLayerStagingServiceURL()
    )
    
    static var test = Service(
        id: "test",
        name: NSLocalizedString("Test", comment: "Server setting name"),
        url: SRGIntegrationLayerTestServiceURL()
    )
    
    static var mmf = Service(
        id: "play mmf",
        name: "Play MMF",
        url: mmfUrl
    )
    
    private static var mmfUrl: URL = {
        guard let mmfUrlString = Bundle.main.object(forInfoDictionaryKey: "PlayMMFServiceURL") as? String,
              !mmfUrlString.isEmpty else {
            return URL(string: "https://play-mmf.herokuapp.com")!
        }
        return URL(string: mmfUrlString)!
    }()
    
    static var samProduction = Service(
        id: "sam production",
        name: "SAM \(NSLocalizedString("Production", comment: "Server setting name"))",
        url: SRGIntegrationLayerProductionServiceURL().appendingPathComponent("sam")
    )
    
    static var samStage = Service(
        id: "sam stage",
        name: "SAM \(NSLocalizedString("Stage", comment: "Server setting name"))",
        url: SRGIntegrationLayerStagingServiceURL().appendingPathComponent("sam")
    )
    
    static var samTest = Service(
        id: "sam test",
        name: "SAM \(NSLocalizedString("Test", comment: "Server setting name"))",
        url: SRGIntegrationLayerTestServiceURL().appendingPathComponent("sam")
    )
    
    static var services: [Service] = [production, stage, test, mmf, samProduction, samStage, samTest]
    
    static func service(forId id: String?) -> Service {
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
    @objc static func name(forServiceId serviceId: String) -> String {
        return Service.service(forId: serviceId).name
    }
    
    @objc static func url(forServiceId serviceId: String) -> URL {
        return Service.service(forId: serviceId).url
    }
}
