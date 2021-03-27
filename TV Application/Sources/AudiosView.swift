//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

class AudioModel: ObservableObject {
    struct RadioItem: Identifiable {
        let index: Int
        let channel: RadioChannel
        let model: HomeModel
        
        var id: Int {
            return index
        }
    }
    
    let items: [RadioItem] = {
        var items = [RadioItem]()
        for (index, channel) in ApplicationConfiguration.shared.radioChannels.enumerated() {
            let model = HomeModel(id: .audio(channel: channel))
            let item = RadioItem(index: index, channel: channel, model: model)
            items.append(item)
        }
        return items
    }()
}

struct AudiosView: View {
    @StateObject var model = AudioModel()
    @State var currentIndex = 0
    
    private var currentItem: AudioModel.RadioItem {
        return model.items[currentIndex]
    }
    
    var body: some View {
        RadioChannelSelector(model: model) { index in
            currentIndex = index
        }
        RadioChannelView(model: currentItem.model)
    }
}

struct RadioChannelSelector: View {
    let model: AudioModel
    let action: (Int) -> Void
    
    var body: some View {
        ScrollView(.horizontal) {
            HStack {
                ForEach(model.items) { item in
                    Button(action: {
                        item.model.refresh()
                        action(item.index)
                    }) {
                        Text(item.channel.name)
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 60)
                }
            }
        }
    }
}

struct RadioChannelView: View {
    let model: HomeModel
    
    init(model: HomeModel) {
        self.model = model
    }
    
    var body: some View {
        HomeView(model: model)
            .onAppear {
                model.refresh()
            }
            .onDisappear {
                model.cancelRefresh()
            }
            .onWake {
                model.refresh()
            }
    }
}
