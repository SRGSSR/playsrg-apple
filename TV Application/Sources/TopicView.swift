//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

struct TopicView: View {
    @ObservedObject var model: PageModel
    
    init(_ topic: SRGTopic) {
        model = PageModel(id: .topic(topic: topic))
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
