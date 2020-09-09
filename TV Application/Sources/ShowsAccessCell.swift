//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

struct ShowsAccessCell: View {
    var body: some View {
        HStack {
            Button(action: { /* Open show list */ }) {
                Text("A to Z")
            }
            Button(action: { /* Open calendar */ }) {
                Text("By date")
            }
        }
    }
}
