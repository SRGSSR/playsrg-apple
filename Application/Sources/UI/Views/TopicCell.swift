//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

protocol TopicCellData {
    var title: String? { get }
    var imageUrl: URL? { get }
    var redactionReason: RedactionReasons { get }
    
    #if os(tvOS)
    func action()
    #endif
}

struct TopicCell: View {
    let data: TopicCellData
    
    var body: some View {
        #if os(tvOS)
        CardButton(action: data.action) {
            MainView(data: data)
                .accessibilityElement()
                .accessibilityLabel(data.title ?? "")
                .accessibility(addTraits: .isButton)
        }
        #else
        MainView(data: data)
            .cornerRadius(LayoutStandardViewCornerRadius)
            .accessibilityElement()
            .accessibilityLabel(data.title ?? "")
        #endif
    }
    
    private struct MainView: View {
        let data: TopicCellData
        
        var body: some View {
            ZStack {
                ImageView(url: data.imageUrl)
                    .aspectRatio(contentMode: .fill)
                Rectangle()
                    .fill(Color(white: 0, opacity: 0.2))
                Text(data.title ?? "")
                    .srgFont(.overline)
                    .lineLimit(1)
                    .foregroundColor(.white)
                    .padding(20)
            }
            .redacted(reason: data.redactionReason)
        }
    }
}

extension TopicCell {
    struct Data: TopicCellData {
        let topic: SRGTopic?
        
        var title: String? {
            return topic?.title
        }
        
        var imageUrl: URL? {
            return topic?.imageURL(for: .width, withValue: SizeForImageScale(.small).width, type: .default)
        }
        
        var redactionReason: RedactionReasons {
            return topic == nil ? .placeholder : .init()
        }
        
        #if os(tvOS)
        func action() {
            if let topic = topic {
                navigateToTopic(topic)
            }
        }
        #endif
    }
    
    init(topic: SRGTopic?) {
        self.init(data: Data(topic: topic))
    }
}

struct TopicCell_Previews: PreviewProvider {
    private struct MockData: TopicCellData {
        var title: String? {
            return "Documentaires"
        }
        
        var imageUrl: URL? {
            return Bundle.main.url(forResource: "topic_documentaires", withExtension: "jpg", subdirectory: "Images")
        }
        
        var redactionReason: RedactionReasons {
            return .init()
        }
        
        #if os(tvOS)
        func action() {}
        #endif
    }
    
    static private let size = LayoutTopicCollectionItemSize()
    
    static var previews: some View {
        Group {
            TopicCell(data: MockData())
            TopicCell(data: TopicCell.Data(topic: nil))
        }
        .previewLayout(.fixed(width: size.width, height: size.height))
    }
}
