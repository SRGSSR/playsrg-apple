//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import NukeUI
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
        ZStack {
            ImageView(source: model.imageUrl)
                .aspectRatio(16 / 9, contentMode: .fit)
                .redactable()
                .layoutPriority(1)
                .overlay(ImageOverlay())
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
            
            // Use stack with competing views to have a 50/50 horizontal split
            HStack {
                DescriptionView(model: model)
                Color.clear
            }
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
                if let properties = model.availabilityBadgeProperties {
                    Badge(text: properties.text, color: Color(properties.color))
                }
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
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .padding(.horizontal, 56)
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
            ProgramPreview(program: Mock.program(.overflow))
            ProgramPreview(program: nil)
        }
        .previewLayout(.fixed(width: 1920, height: 700))
    }
}
