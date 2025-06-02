//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

enum Mock {
    enum Bucket: String {
        case standard
        case overflow
    }

    static func bucket(_ kind: Bucket = .standard) -> SRGItemBucket {
        mockObject(kind.rawValue, type: SRGItemBucket.self)
    }

    enum Channel: String {
        case unknown
        case standard
        case overflow
        case standardWithoutLogo
        case overflowWithoutLogo
    }

    static func channel(_ kind: Channel = .standard) -> SRGChannel {
        mockObject(kind.rawValue, type: SRGChannel.self)
    }

    static func playChannel(_ kind: Channel = .standard) -> PlayChannel {
        PlayChannel(wrappedValue: mockObject(kind.rawValue, type: SRGChannel.self), external: false)
    }

    enum ContentSection: String {
        case standard
        case overflow
    }

    static func contentSection(_ kind: ContentSection = .standard) -> SRGContentSection {
        mockObject(kind.rawValue, type: SRGContentSection.self)
    }

    enum FocalPoint: String {
        case none
        case left
        case right
        case top
        case bottom
        case topLeft
        case topRight
        case bottomLeft
        case bottomRight
    }

    static func focalPoint(_ kind: FocalPoint = .none) -> SRGFocalPoint? {
        switch kind {
        case .none:
            nil
        default:
            mockObject(kind.rawValue, type: SRGFocalPoint.self)
        }
    }

    enum Highlight {
        case standard
        case overflow
        case short
        case topLeftAligned
        case bottomRightAligned
    }

    static func highlight(_ kind: Highlight = .standard) -> PlaySRG.Highlight {
        switch kind {
        case .standard:
            PlaySRG.Highlight(
                title: "Jeune et Golri - Saison 1 inédite!",
                summary: "Prune, stand-uppeuse jeune et golri, rencontre Francis, vieux et dépité.  Elle qui devait bosser son premier spectacle s'embarque dans cette love story inattendue!",
                image: SRGImage(url: URL(string: "https://il.srgssr.ch/integrationlayer/2.0/image-scale-sixteen-to-nine/https://play-pac-public-production.s3.eu-central-1.amazonaws.com/images/4fe0346b-3b3b-47cf-b31a-9d4ae4e3552a.jpeg"), variant: .default),
                imageFocalPoint: nil
            )
        case .overflow:
            PlaySRG.Highlight(
                title: .loremIpsum,
                summary: .loremIpsum,
                image: SRGImage(url: URL(string: "https://il.srgssr.ch/integrationlayer/2.0/image-scale-sixteen-to-nine/https://play-pac-public-production.s3.eu-central-1.amazonaws.com/images/4fe0346b-3b3b-47cf-b31a-9d4ae4e3552a.jpeg"), variant: .default),
                imageFocalPoint: nil
            )
        case .short:
            PlaySRG.Highlight(
                title: "Title",
                summary: "Description",
                image: SRGImage(url: URL(string: "https://il.srgssr.ch/integrationlayer/2.0/image-scale-sixteen-to-nine/https://play-pac-public-production.s3.eu-central-1.amazonaws.com/images/b75b85ed-5fbd-4f1f-983b-80ac0d92764b.jpeg"), variant: .default),
                imageFocalPoint: nil
            )
        case .topLeftAligned:
            PlaySRG.Highlight(
                title: "Top left",
                summary: "Summary",
                image: SRGImage(url: URL(string: "https://il.srgssr.ch/integrationlayer/2.0/image-scale-sixteen-to-nine/https://play-pac-public-production.s3.eu-central-1.amazonaws.com/images/4fe0346b-3b3b-47cf-b31a-9d4ae4e3552a.jpeg"), variant: .default),
                imageFocalPoint: focalPoint(.topLeft)
            )
        case .bottomRightAligned:
            PlaySRG.Highlight(
                title: "Bottom right",
                summary: "Summary",
                image: SRGImage(url: URL(string: "https://il.srgssr.ch/integrationlayer/2.0/image-scale-sixteen-to-nine/https://play-pac-public-production.s3.eu-central-1.amazonaws.com/images/4fe0346b-3b3b-47cf-b31a-9d4ae4e3552a.jpeg"), variant: .default),
                imageFocalPoint: focalPoint(.bottomRight)
            )
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
        mockObject(kind.rawValue, type: SRGMedia.self)
    }

    #if os(iOS)
        static func download(_ kind: Media = .standard) -> Download? {
            let media = mockObject(kind.rawValue, type: SRGMedia.self)
            return Download.add(for: media)
        }

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
        case fallbackImageUrl
    }

    static func program(_ kind: Program = .standard) -> SRGProgram {
        mockObject(kind.rawValue, type: SRGProgram.self)
    }

    static func playProgram(_ kind: Program = .standard) -> PlayProgram {
        PlayProgram(wrappedValue: program(kind), nextProgramStartDate: nil)
    }

    enum Show: String {
        case standard
        case overflow
        case short
    }

    static func show(_ kind: Show = .standard) -> SRGShow {
        mockObject(kind.rawValue, type: SRGShow.self)
    }

    enum Page: String {
        case standard
        case overflow
        case short
    }

    static func page(_ kind: Page = .standard) -> SRGContentPage {
        mockObject(kind.rawValue, type: SRGContentPage.self)
    }

    enum Topic: String {
        case standard
        case overflow
    }

    static func topic(_ kind: Topic = .standard) -> SRGTopic {
        mockObject(kind.rawValue, type: SRGTopic.self)
    }

    private static func mockObject<T>(_ name: String, type: T.Type) -> T {
        let clazz: AnyClass = type as! AnyClass
        let asset = NSDataAsset(name: "\(NSStringFromClass(clazz))_\(name)")!
        let jsonData = try! JSONSerialization.jsonObject(with: asset.data, options: []) as? [String: Any]
        return try! MTLJSONAdapter(modelClass: clazz)?.model(fromJSONDictionary: jsonData) as! T
    }
}
