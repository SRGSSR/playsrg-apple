//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGAppearanceSwift
import SRGDataProviderModel
import SwiftUI

// MARK: View

/// Behavior: h-exp, v-exp
struct ProgramPreview: View {
    @Binding var program: SRGProgram?
    
    @StateObject private var model = ProgramPreviewModel()
    
    init(program: SRGProgram?) {
        _program = .constant(program)
    }
    
    var body: some View {
        HStack {
            DescriptionView(model: model)
            ImageView(url: model.imageUrl)
                .aspectRatio(16 / 9, contentMode: .fit)
                .redactable()
                .layoutPriority(1)
                .overlay(ImageOverlay())
        }
        .redactedIfNil(program)
        .onAppear {
            model.program = program
        }
        .onChange(of: program) { newValue in
            model.program = newValue
        }
    }
    
    /// Behavior: h-exp, v-exp
    struct DescriptionView: View {
        @ObservedObject var model: ProgramPreviewModel
        
        var body: some View {
            VStack(alignment: .leading, spacing: 4) {
                if let subtitle = model.subtitle {
                    Text(subtitle)
                        .srgFont(.H4)
                        .lineLimit(1)
                        .foregroundColor(.srgGray96)
                }
                Text(model.title)
                    .srgFont(.H2)
                    .lineLimit(2)
                    .foregroundColor(.srgGrayC7)
                Text(model.timeInformation)
                    .srgFont(.H4)
                    .lineLimit(1)
                    .foregroundColor(.srgGray96)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(.horizontal, 60)
            .padding(.top, 180)
            .padding(.bottom, 40)
        }
    }
    
    /// Behavior: h-exp, v-exp
    private struct ImageOverlay: View {
        var body: some View {
            LinearGradient(gradient: Gradient(colors: [.srgGray16, .clear]), startPoint: .leading, endPoint: .center)
        }
    }
}

// MARK: Preview

struct ProgramPreview_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ProgramPreview(program: Mock.program())
            ProgramPreview(program: nil)
        }
        .previewLayout(.fixed(width: 1920, height: 600))
    }
}
