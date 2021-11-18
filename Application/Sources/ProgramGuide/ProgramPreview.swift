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
    let program: SRGProgram?
    
    private var imageUrl: URL? {
        return program?.imageUrl(for: .large)
    }
    
    var body: some View {
        HStack {
            DescriptionView(program: program)
            ImageView(url: imageUrl)
                .aspectRatio(16 / 9, contentMode: .fit)
                .redactable()
                .layoutPriority(1)
                .overlay(ImageOverlay())
        }
        .redactedIfNil(program)
    }
    
    /// Behavior: h-exp, v-exp
    struct DescriptionView: View {
        let program: SRGProgram?
        
        private var subtitle: String? {
            return program?.title
        }
        
        private var title: String {
            if let subtitle = program?.subtitle {
                return subtitle
            }
            else {
                return program?.title ?? "                "
            }
        }
        
        private var timeInformation: String {
            guard let program = program else { return "       " }
            let nowDate = Date()
            if program.play_contains(nowDate) {
                let remainingTimeInterval = program.endDate.timeIntervalSince(nowDate)
                let remainingTime = PlayRemainingTimeFormattedDuration(remainingTimeInterval)
                return String(format: NSLocalizedString("%@ remaining", comment: "Text displayed on live cells telling how much time remains for a program currently on air"), remainingTime)
            }
            else {
                let startTime = DateFormatter.play_time.string(from: program.startDate)
                let endTime = DateFormatter.play_time.string(from: program.endDate)
                // Unbreakable spaces before / after the separator
                return "\(startTime) - \(endTime)"
            }
        }
        
        var body: some View {
            VStack(alignment: .leading, spacing: 4) {
                if let subtitle = subtitle {
                    Text(subtitle)
                        .srgFont(.H4)
                        .lineLimit(1)
                        .foregroundColor(.srgGray96)
                }
                Text(title)
                    .srgFont(.H2)
                    .lineLimit(2)
                    .foregroundColor(.srgGrayC7)
                Text(timeInformation)
                    .srgFont(.H4)
                    .lineLimit(1)
                    .foregroundColor(.srgGray96)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(.horizontal, 60)
            .padding(.vertical, 100)
        }
    }
    
    /// Behavior: h-exp, v-exp
    private struct ImageOverlay: View {
        var body: some View {
            LinearGradient(gradient: Gradient(colors: [.black, .clear]), startPoint: .leading, endPoint: .center)
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
