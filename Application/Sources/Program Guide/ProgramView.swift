//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

// MARK: View

struct ProgramView: View {
    @Binding var program: SRGProgram
    @StateObject private var model = ProgramViewModel()
    
    static func viewController(for program: SRGProgram) -> UIViewController {
        return UIHostingController(rootView: ProgramView(program: program))
    }
    
    init(program: SRGProgram) {
        _program = .constant(program)
    }
    
    var body: some View {
        Text(program.title)
            .padding()
            .onAppear {
                model.program = program
            }
            .onChange(of: program) { newValue in
                model.program = newValue
            }
    }
}

// MARK: Preview

struct ProgramView_Previews: PreviewProvider {
    static var previews: some View {
        ProgramView(program: Mock.program())
            .previewLayout(.sizeThatFits)
    }
}
