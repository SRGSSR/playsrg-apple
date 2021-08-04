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
        VStack(spacing: 18) {
            Handle()
            ScrollView {
                VStack(spacing: 10) {
                    ImageView(url: model.imageUrl)
                        .aspectRatio(16 / 9, contentMode: .fit)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(LayoutStandardViewCornerRadius)
                    DescriptionView(model: model)
                    Spacer()
                }
            }
        }
        .padding([.horizontal, .top], 14)
        .onAppear {
            model.program = program
        }
        .onChange(of: program) { newValue in
            model.program = newValue
        }
    }
    
    // Behavior: h-hug, v-hug
    private struct Handle: View {
        var body: some View {
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.white)
                .frame(width: 36, height: 4)
        }
    }
    
    // Behavior: h-exp, v-hug
    private struct DescriptionView: View {
        @ObservedObject var model: ProgramViewModel
        
        var body: some View {
            VStack(spacing: 12) {
                VStack(spacing: 6) {
                    if let formattedTimeAndDate = model.formattedTimeAndDate {
                        Text(formattedTimeAndDate)
                            .srgFont(.caption)
                            .lineLimit(1)
                            .foregroundColor(.srgGray96)
                    }
                    TitleView(model: model)
                }
                if let summary = model.summary {
                    Text(summary)
                        .srgFont(.body)
                        .foregroundColor(.srgGray96)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
    
    // Behavior: h-hug, v-hug
    private struct TitleView: View {
        @ObservedObject var model: ProgramViewModel
        
        var body: some View {
            VStack(spacing: 0) {
                if let title = model.title {
                    Text(title)
                        .srgFont(.H2)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.srgGrayC7)
                }
                if let lead = model.lead {
                    Text(lead)
                        .srgFont(.H4)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.srgGray96)
                }
            }
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
