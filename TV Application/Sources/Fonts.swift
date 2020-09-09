//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

// FIXME: Should be moved to SRG Appearance, see issues
//          https://github.com/SRGSSR/srgappearance-apple/issues/3
//          https://github.com/SRGSSR/srgappearance-apple/issues/4

enum SRGFont {
    enum Style {
        case regular
        case bold
        case heavy
        case light
        case medium
        case italic
        case boldItalic
        case regularSerif
        case lightSerif
        case mediumSerif
        
        fileprivate var name: String {
            switch self {
            case .regular:
                return "SRGSSRTypeTextApp-Regular"
            case .bold:
                return "SRGSSRTypeTextApp-Bold"
            case .heavy:
                return "SRGSSRTypeTextApp-Heavy"
            case .light:
                return "SRGSSRTypeTextApp-Light"
            case .medium:
                return "SRGSSRTypeTextApp-Medium"
            case .italic:
                return "SRGSSRTypeTextApp-Italic"
            case .boldItalic:
                return "SRGSSRTypeTextApp-BoldItalic"
            case .regularSerif:
                return "SRGSSRTypeSerifTextApp-Regular"
            case .lightSerif:
                return "SRGSSRTypeSerifTextApp-Light"
            case .mediumSerif:
                return "SRGSSRTypeTextApp-Regular"
            }
        }
    }
    
    enum Size {
        case caption
        case subtitle
        case body
        case headline
        case title
        
        fileprivate var properties: (size: CGFloat, textStyle: Font.TextStyle) {
            switch self {
            case .caption:
                return (20, .caption)
            case .subtitle:
                return (29, .body)
            case .body:
                return (26, .body)
            case .headline:
                return (31, .headline)
            case .title:
                return (48, .title)
            }
        }
    }
    
    static public func font(_ style: Style, size: Size) -> Font {
        let properties = size.properties
        return .custom(style.name, size: properties.size, relativeTo: properties.textStyle)
    }
    
    static public func font(_ style: Style, fixedSize: CGFloat) -> Font {
        return .custom(style.name, fixedSize: fixedSize)
    }
}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension Text {
    func srgFont(_ style: SRGFont.Style, size: SRGFont.Size) -> Text {
        return font(SRGFont.font(style, size: size))
    }
    
    func srgFont(_ style: SRGFont.Style, fixedSize: CGFloat) -> Text {
        return font(SRGFont.font(style, fixedSize: fixedSize))
    }
}
