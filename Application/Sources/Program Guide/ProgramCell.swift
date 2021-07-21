//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGAppearanceSwift
import SwiftUI

// MARK: Cell

struct ProgramCell: View {
    let program: SRGProgram
    
    @SRGScaledMetric var timeRangeWidth: CGFloat = 90
    
    private var timeRange: String {
        let startTime = DateFormatter.play_time.string(from: program.startDate)
        let endTime = DateFormatter.play_time.string(from: program.endDate)
        return "\(startTime) - \(endTime)"
    }
    
    var body: some View {
        HStack(spacing: 10) {
            Text(timeRange)
                .srgFont(.subtitle1)
                .foregroundColor(.srgGray96)
                .frame(width: timeRangeWidth, alignment: .leading)
            if program.mediaURN != nil {
                Image("play_circle")
                    .foregroundColor(.srgGrayC7)
            }
            Text(program.title)
                .srgFont(.body)
                .foregroundColor(.srgGrayC7)
            Spacer()
        }
        .lineLimit(2)
        .padding(.horizontal, 16)
        .frame(maxHeight: .infinity)
        .background(Color.srgGray23)
        .cornerRadius(4)
    }
}

// MARK: Sizing

class ProgramCellSize: NSObject {
    @objc static func fullWidth() -> NSCollectionLayoutSize {
        return NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(50))
    }
}

// MARK: Preview

struct ProgramCell_Previews: PreviewProvider {
    static private let size = ProgramCellSize.fullWidth().previewSize
    
    static var previews: some View {
        ProgramCell(program: Mock.program(.overflow))
            .previewLayout(.fixed(width: size.width, height: size.height))
    }
}
