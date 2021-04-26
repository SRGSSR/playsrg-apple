//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

protocol ShowCellData {
    var title: String? { get }
    var imageUrl: URL? { get }
    var redactionReason: RedactionReasons { get }
    
    #if os(tvOS)
    func action()
    #endif
}

struct ShowCell: View {
    let data: ShowCellData
    let direction: StackDirection
    
    init(data: ShowCellData, direction: StackDirection = .vertical) {
        self.data = data
        self.direction = direction
    }
    
    var body: some View {
        Group {
            #if os(tvOS)
            LabeledCardButton(action: data.action) {
                ImageView(url: data.imageUrl)
                    .aspectRatio(contentMode: .fill)
                    .accessibilityElement()
                    .accessibilityLabel(data.title ?? "")
                    .accessibility(addTraits: .isButton)
            } label: {
                DescriptionView(data: data)
            }
            #else
            Stack(direction: direction) {
                ImageView(url: data.imageUrl)
                    .aspectRatio(contentMode: .fill)
                DescriptionView(data: data)
                    .padding(.bottom, 5)
                    .padding(.horizontal, 8)
            }
            .background(Color(.play_cardGrayBackground))
            .cornerRadius(LayoutStandardViewCornerRadius)
            .accessibilityElement()
            .accessibilityLabel(data.title ?? "")
            #endif
        }
        .redacted(reason: data.redactionReason)
    }
    
    private struct DescriptionView: View {
        let data: ShowCellData
        
        private var title: String {
            return data.title ?? String(repeating: " ", count: .random(in: 10..<20))
        }
        
        var body: some View {
            Text(title)
                .srgFont(.subtitle)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .topLeading)
        }
    }
}

extension ShowCell {
    struct Data: ShowCellData {
        let show: SRGShow?
        
        var title: String? {
            return show?.title
        }
        
        var imageUrl: URL? {
            return show?.imageURL(for: .width, withValue: SizeForImageScale(.small).width, type: .default)
        }
        
        var redactionReason: RedactionReasons {
            return show == nil ? .placeholder : .init()
        }
        
        #if os(tvOS)
        func action() {
            if let show = show {
                navigateToShow(show)
            }
        }
        #endif
    }
    
    init(show: SRGShow?, direction: StackDirection = .vertical) {
        self.init(data: Data(show: show), direction: direction)
    }
}

struct ShowCell_Previews: PreviewProvider {
    private struct MockData: ShowCellData {
        var title: String? {
            return "19h30"
        }
        
        var imageUrl: URL? {
            return Bundle.main.url(forResource: "show_19h30", withExtension: "jpg", subdirectory: "Images")
        }
        
        var redactionReason: RedactionReasons {
            return .init()
        }
        
        #if os(tvOS)
        func action() {}
        #endif
    }
    
    static private let size = LayoutCollectionItemSize(LayoutStandardCellWidth, .showSwimlaneOrGrid, .regular)
    
    static var previews: some View {
        Group {
            ShowCell(data: MockData())
                .previewDisplayName("Cell")
            ShowCell(data: ShowCell.Data(show: nil))
                .previewDisplayName("Placeholder")
        }
        .previewLayout(.fixed(width: size.width, height: size.height))
    }
}
