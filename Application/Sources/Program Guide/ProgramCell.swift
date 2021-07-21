//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

// MARK: Cell

struct ProgramCell: View {
    let program: SRGProgram
    
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
                .frame(width: 130)
            if program.mediaURN != nil {
                Image("play_circle")
                    .foregroundColor(.srgGrayC7)
            }
            Text(program.title)
                .srgFont(.body)
                .foregroundColor(.srgGrayC7)
            Spacer()
        }
        .lineLimit(1)
        .padding(.horizontal, 16)
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
    static private let size = MediaCellSize.fullWidth().previewSize
    
    static var previews: some View {
        ProgramCell(program: Mock.program(.overflow))
            .previewLayout(.fixed(width: size.width, height: size.height))
    }
}
