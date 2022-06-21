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
    
    enum Highlight {
        case standard
        case overflow
        case short
    }
    
    static func highlight(_ kind: Highlight = .standard) -> PlaySRG.Highlight {
        switch kind {
        case .standard:
            return PlaySRG.Highlight(
                title: "Jeune et Golri - Saison 1 inédite!",
                summary: "Prune, stand-uppeuse jeune et golri, rencontre Francis, vieux et dépité.  Elle qui devait bosser son premier spectacle s'embarque dans cette love story inattendue!",
                image: SRGImage(url: URL(string: "https://il.srgssr.ch/integrationlayer/2.0/image-scale-sixteen-to-nine/https://play-pac-public-production.s3.eu-central-1.amazonaws.com/images/4fe0346b-3b3b-47cf-b31a-9d4ae4e3552a.jpeg"), variant: .default)
            )
        case .overflow:
            return PlaySRG.Highlight(
                title: .loremIpsum,
                summary: .loremIpsum,
                image: SRGImage(url: URL(string: "https://il.srgssr.ch/integrationlayer/2.0/image-scale-sixteen-to-nine/https://play-pac-public-production.s3.eu-central-1.amazonaws.com/images/4fe0346b-3b3b-47cf-b31a-9d4ae4e3552a.jpeg"), variant: .default)
            )
        case .short:
            return PlaySRG.Highlight(
                title: "Title",
                summary: "Description",
                image: SRGImage(url: URL(string: "https://il.srgssr.ch/integrationlayer/2.0/image-scale-sixteen-to-nine/https://play-pac-public-production.s3.eu-central-1.amazonaws.com/images/b75b85ed-5fbd-4f1f-983b-80ac0d92764b.jpeg"), variant: .default))
        }
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
    
#if os(iOS)
    enum Notification: String {
        case standard
        case overflow
    }
    
    static func notification(_ kind: Notification = .standard) -> UserNotification {
        mockObject(kind.rawValue, type: UserNotification.self)
    }
#endif
    
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
#if os(iOS)
        if clazz == UserNotification.self,
           let dictionary = try? PropertyListSerialization.propertyList(from: asset.data, format: nil) as? [String: Any] {
            return UserNotification.init(dictionary: dictionary) as! T
        }
#endif
        let jsonData = try! JSONSerialization.jsonObject(with: asset.data, options: []) as? [String: Any]
        return try! MTLJSONAdapter(modelClass: clazz)?.model(fromJSONDictionary: jsonData) as! T
    }
}
