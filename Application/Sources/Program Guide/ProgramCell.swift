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

// MARK: Preview

struct ProgramCell_Previews: PreviewProvider {
    static var previews: some View {
        ProgramCell(program: Mock.program())
    }
}
