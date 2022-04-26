//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

struct Mock {
    enum Channel: String {
        case unknown
        case standard
        case overflow
        case standardWithoutLogo
        case overflowWithoutLogo
    }
    
    static func channel(_ kind: Channel = .standard) -> SRGChannel {
        return mockObject(kind.rawValue, type: SRGChannel.self)
    }
    
    enum ContentSection: String {
        case standard
        case overflow
    }
    
    static func contentSection(_ kind: ContentSection = .standard) -> SRGContentSection {
        return mockObject(kind.rawValue, type: SRGContentSection.self)
    }
    
    enum Media: String {
        case standard
        case minimal
        case rich
        case overflow
        case blocked
        case livestream
        case noShow
        case fourThree
        case fourFive
        case nineSixteen
        case square
    }
    
    static func media(_ kind: Media = .standard) -> SRGMedia {
        return mockObject(kind.rawValue, type: SRGMedia.self)
    }
    
    enum Program: String {
        case standard
        case overflow
    }
    
    static func program(_ kind: Program = .standard) -> SRGProgram {
        return mockObject(kind.rawValue, type: SRGProgram.self)
    }
    
    enum Show: String {
        case standard
        case overflow
    }
    
    static func show(_ kind: Show = .standard) -> SRGShow {
        return mockObject(kind.rawValue, type: SRGShow.self)
    }
    
    enum Topic: String {
        case standard
        case overflow
    }
    
    static func topic(_ kind: Topic = .standard) -> SRGTopic {
        return mockObject(kind.rawValue, type: SRGTopic.self)
    }
    
    private static func mockObject<T>(_ name: String, type: T.Type) -> T {
        let clazz: AnyClass = type as! AnyClass
        let asset = NSDataAsset(name: "\(NSStringFromClass(clazz))_\(name)")!
        let jsonData = try! JSONSerialization.jsonObject(with: asset.data, options: []) as? [String: Any]
        return try! MTLJSONAdapter(modelClass: clazz)?.model(fromJSONDictionary: jsonData) as! T
    }
}
