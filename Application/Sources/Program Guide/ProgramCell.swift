//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

// MARK: Cell

struct ProgramCell: View {
    let program: SRGProgram
    
    var body: some View {
        Text(program.title)
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
        ProgramCell(program: Mock.program())
            .previewLayout(.fixed(width: size.width, height: size.height))
    }
}
