//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGAppearanceSwift
import SwiftUI

// MARK: Cell

struct ProgramCell: View {
    @Binding var program: SRGProgram
    @StateObject private var model = ProgramCellViewModel()
    
    @Environment(\.isSelected) private var isSelected
    @SRGScaledMetric var timeRangeWidth: CGFloat = 90
    
    init(program: SRGProgram) {
        _program = .constant(program)
    }
    
    var body: some View {
        ZStack {
            HStack(spacing: 10) {
                if let timeRange = model.timeRange {
                    Text(timeRange)
                        .srgFont(.subtitle1)
                        .foregroundColor(.srgGray96)
                        .frame(width: timeRangeWidth, alignment: .leading)
                }
                if model.canPlay {
                    Image("play_circle")
                        .foregroundColor(.srgGrayC7)
                }
                if let title = program.title {
                    Text(title)
                        .srgFont(.body)
                        .foregroundColor(.srgGrayC7)
                }
                Spacer()
            }
            .lineLimit(2)
            .padding(.horizontal, 16)
            .frame(maxHeight: .infinity)
            .background(Color.srgGray23)
            
            if let progress = model.progress {
                ProgressBar(value: progress)
                    .frame(height: LayoutProgressBarHeight)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            }
        }
        .selectionAppearance(.dimmed, when: isSelected)
        .cornerRadius(4)
        .accessibilityElement(label: accessibilityLabel, hint: accessibilityHint)
        .onAppear {
            model.program = program
        }
        .onChange(of: program) { newValue in
            model.program = newValue
        }
    }
}

// MARK: Accessibility

private extension ProgramCell {
    var accessibilityLabel: String? {
        return model.accessibilityLabel
    }
    
    var accessibilityHint: String? {
        return PlaySRGAccessibilityLocalizedString("Opens details.", comment: "Program cell hint")
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
    private static let size = ProgramCellSize.fullWidth().previewSize
    
    static var previews: some View {
        ProgramCell(program: Mock.program(.overflow))
            .previewLayout(.fixed(width: size.width, height: size.height))
    }
}
