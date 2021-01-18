//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import UIKit
import SwiftUI

// FIXME: Should be moved to SRG Appearance, see issues
//          https://github.com/SRGSSR/srgappearance-apple/issues/3
//          https://github.com/SRGSSR/srgappearance-apple/issues/4

enum SRGFont {
    enum Kind {
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
    
    enum Style {
        case title1
        case title2
        case headline1
        case headline2
        case subtitle
        case body
        case button1
        case button2
        case overline
        case label
        case caption
        
        fileprivate var properties: (size: CGFloat, kind: SRGFont.Kind) {
            switch self {
            case .title1:
                return (48, .bold)
            case .title2:
                return (42, .medium)
            case .headline1:
                return (32, .regular)
            case .headline2:
                return (30, .medium)
            case .subtitle:
                return (32, .light)
            case .body:
                return (30, .regular)
            case .button1:
                return (32, .medium)
            case .button2:
                return (26, .regular)
            case .overline:
                return (24, .regular)
            case .label:
                return (20, .bold)
            case .caption:
                return (18, .medium)
            }
        }
    }
    
    static public func font(_ style: Style, relativeTo textStyle: Font.TextStyle = .body) -> Font {
        let properties = style.properties
        return .custom(properties.kind.name, size: properties.size, relativeTo: textStyle)
    }
    
    static public func uiFont(_ style: Style, relativeTo textStyle: UIFont.TextStyle = .body) -> UIFont {
        let properties = style.properties
        return UIFontMetrics(forTextStyle: textStyle).scaledFont(for: uiFont(properties.kind, fixedSize: properties.size))
    }
    
    static public func font(_ kind: Kind, fixedSize: CGFloat) -> Font {
        return .custom(kind.name, fixedSize: fixedSize)
    }
    
    static public func uiFont(_ kind: Kind, fixedSize: CGFloat) -> UIFont {
        return UIFont(name: kind.name, size: fixedSize)!
    }
}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension Text {
    func srgFont(_ style: SRGFont.Style, relativeTo textStyle: Font.TextStyle = .body) -> Text {
        return font(SRGFont.font(style, relativeTo: textStyle))
    }
    
    func srgFont(_ kind: SRGFont.Kind, fixedSize: CGFloat) -> Text {
        return font(SRGFont.font(kind, fixedSize: fixedSize))
    }
}

struct Fonts_Previews: PreviewProvider {
    private struct TextPreview: View {
        let text: String
        let style: SRGFont.Style
        
        var body: some View {
            Text(text)
                .srgFont(style)
                .padding()
        }
    }
    
    static var previews: some View {
        VStack(alignment: .leading) {
            Group {
                TextPreview(text: "Title 1", style: .title1)
                TextPreview(text: "Title 2", style: .title2)
                TextPreview(text: "Headline 1", style: .headline1)
                TextPreview(text: "Headline 2", style: .headline2)
                TextPreview(text: "Subtitle", style: .subtitle)
            }
            
            Group {
                TextPreview(text: "Body", style: .body)
                TextPreview(text: "Button 1", style: .button1)
                TextPreview(text: "Button 2", style: .button2)
                TextPreview(text: "Overline", style: .overline)
                TextPreview(text: "Caption", style: .caption)
                TextPreview(text: "Label", style: .label)
            }
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
