//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

struct ProgressBar: View {
    let value: Double
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.white)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                Rectangle()
                    .fill(Color(.play_progressRed))
                    .frame(width: geometry.size.width * CGFloat(value), height: geometry.size.height)
            }
        }
    }
    
    init(value: Double) {
        self.value = value.clamped(to: 0...1)
    }
}

struct ProgressBar_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ProgressBar(value: 0)
                .previewLayout(.fixed(width: 400, height: 2))
                .previewDisplayName("0%")
            
            ProgressBar(value: 0.6)
                .previewLayout(.fixed(width: 400, height: 2))
                .previewDisplayName("60%")
            
            ProgressBar(value: 1)
                .previewLayout(.fixed(width: 400, height: 2))
                .previewDisplayName("100%")
        }
    }
}
