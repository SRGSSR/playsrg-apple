//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

// MARK: View

// Behavior: h-exp, v-hug
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
        VStack {
            ImageView(url: model.imageUrl)
                .aspectRatio(16 / 9, contentMode: .fit)
                .background(Color.white.opacity(0.1))
                .cornerRadius(LayoutStandardViewCornerRadius)
            DescriptionView(model: model)
            Spacer()
        }
        .padding([.horizontal, .top], 14)
        .onAppear {
            model.program = program
        }
        .onChange(of: program) { newValue in
            model.program = newValue
        }
    }
    
    // Behavior: h-exp, v-hug
    private struct DescriptionView: View {
        @ObservedObject var model: ProgramViewModel
        
        var body: some View {
            VStack {
                if let title = model.title {
                    Text(title)
                        .srgFont(.H2)
                        .lineLimit(2)
                        .foregroundColor(.srgGrayC7)
                }
                if let lead = model.lead {
                    Text(lead)
                        .srgFont(.H4)
                        .lineLimit(2)
                        .foregroundColor(.srgGray96)
                }
                if let summary = model.summary {
                    Text(summary)
                        .srgFont(.body)
                        .multilineTextAlignment(.leading)
                        .foregroundColor(.srgGray96)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: Preview

struct ProgramView_Previews: PreviewProvider {
    private static let size = CGSize(width: 320, height: 600)
    
    static var previews: some View {
        ProgramView(program: Mock.program())
            .previewLayout(.fixed(width: size.width, height: size.height))
    }
}
