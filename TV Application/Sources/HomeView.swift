//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

struct HomeView: View {
    @ObservedObject var model: HomeModel
    
    var body: some View {
        ScrollView {
            VStack {
                ForEach(model.rows) { row in
                    HomeSwimlane(row: row)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onAppear {
            model.refresh()
        }
        .ignoresSafeArea(.all, edges: [.leading, .trailing, .bottom])
    }
}
