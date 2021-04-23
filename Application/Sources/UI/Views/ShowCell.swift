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
    let layout: StackLayout
    
    init(data: ShowCellData, layout: StackLayout = .vertical) {
        self.data = data
        self.layout = layout
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
            Group {
                Stack(layout: layout) {
                    ImageView(url: data.imageUrl)
                        .aspectRatio(contentMode: .fill)
                    DescriptionView(data: data)
                        .padding(.bottom, 5)
                        .padding(.horizontal, 8)
                }
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
    
    init(show: SRGShow?, layout: StackLayout = .vertical) {
        self.init(data: Data(show: show), layout: layout)
    }
}

struct ShowCell_Previews: PreviewProvider {
    private struct MockData: ShowCellData {
        var title: String? {
            return "19h30"
        }
        
        var imageUrl: URL? {
            return URL(string: "https://www.rts.ch/2019/08/28/11/33/10667272.image/16x9/scale/width/960")
        }
        
        var redactionReason: RedactionReasons {
            return .init()
        }
        
        #if os(tvOS)
        func action() {}
        #endif
    }
    
    static private let size = LayoutCollectionItemSize(LayoutStandardCellWidth, .showSwimlaneOrGrid)
    
    static var previews: some View {
        Group {
            ShowCell(data: MockData())
            ShowCell(data: ShowCell.Data(show: nil))
        }
        .previewLayout(.fixed(width: size.width, height: size.height))
    }
}
