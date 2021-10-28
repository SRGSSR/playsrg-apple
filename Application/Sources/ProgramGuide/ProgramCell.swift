//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGAppearanceSwift
import SwiftUI

// MARK: Cell

struct ProgramCell: View {
    private struct FlatButtonStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .scaleEffect(!configuration.isPressed ? 1 : 0.98)
        }
    }
    
    @Binding var program: SRGProgram
    let direction: StackDirection
    
    @StateObject private var model = ProgramCellViewModel()
    
    @Environment(\.isSelected) private var isSelected
    
    init(program: SRGProgram, direction: StackDirection) {
        _program = .constant(program)
        self.direction = direction
    }
    
    var body: some View {
        Group {
#if os(tvOS)
            GeometryReader { geometry in
                Button(action: action) {
                    MainView(model: model, direction: direction)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .accessibilityElement(label: accessibilityLabel, hint: accessibilityHint, traits: .isButton)
                }
                .buttonStyle(FlatButtonStyle())
            }
#else
            MainView(model: model, direction: direction)
                .selectionAppearance(.dimmed, when: isSelected)
                .accessibilityElement(label: accessibilityLabel, hint: accessibilityHint)
#endif
        }
        .onAppear {
            model.program = program
        }
        .onChange(of: program) { newValue in
            model.program = newValue
        }
    }
    
#if os(tvOS)
    private func action() {
        navigateToProgram(program)
    }
#endif
    
    /// Behavior: h-exp, v-exp
    private struct MainView: View {
        @ObservedObject var model: ProgramCellViewModel
        let direction: StackDirection
        
        @SRGScaledMetric var timeRangeFixedWidth: CGFloat = 90
        @State private var availableSize: CGSize = .zero
        @Environment(\.isFocused) private var isFocused
        
        private var timeRangeWidth: CGFloat {
            return direction == .horizontal ? timeRangeFixedWidth : .infinity
        }
        
        private var timeRangeLineLimit: Int {
            return direction == .horizontal ? 2 : 1
        }
        
        private var alignment: StackAlignment {
            return direction == .horizontal ? .center : .leading
        }
        
        private var horizontalPadding: CGFloat {
            return direction == .horizontal ? 16 : 8
        }
        
        private var topPadding: CGFloat {
            return direction == .horizontal ? 0 : 16
        }
        
        private var bottomPadding: CGFloat {
            return direction == .horizontal ? 0 : 2
        }
        
        private var isCompact: Bool {
            return availableSize.width < 100
        }
        
        var body: some View {
            ZStack {
                Stack(direction: direction, alignment: alignment, spacing: 10) {
                    if let timeRange = model.timeRange {
                        Text(timeRange)
                            .srgFont(.subtitle1)
                            .lineLimit(timeRangeLineLimit)
                            .foregroundColor(.srgGray96)
                            .frame(maxWidth: timeRangeWidth, alignment: .leading)
                    }
                    TitleView(model: model, compact: isCompact)
                    Spacer()
                }
                .padding(.horizontal, horizontalPadding)
                .padding(.top, topPadding)
                .padding(.bottom, bottomPadding)
                .frame(maxHeight: .infinity)
                .background(!isFocused ? Color.srgGray23 : Color.srgGray33)
                
                if let progress = model.progress {
                    ProgressBar(value: progress)
                        .frame(height: LayoutProgressBarHeight)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                }
            }
            .cornerRadius(4)
            .readSize { size in
                self.availableSize = size
            }
        }
    }
    
    /// Behavior: h-hug, v-hug
    private struct TitleView: View {
        @ObservedObject var model: ProgramCellViewModel
        let compact: Bool
        
        var body: some View {
            HStack(spacing: 10) {
                if !compact && model.canPlay {
                    Image("play_circle")
                        .foregroundColor(.srgGrayC7)
                }
                if let title = model.program?.title {
                    Text(title)
                        .srgFont(.body)
                        .lineLimit(1)
                        .foregroundColor(.srgGrayC7)
                }
            }
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
        ProgramCell(program: Mock.program(), direction: .horizontal)
            .previewLayout(.fixed(width: size.width, height: size.height))
        ProgramCell(program: Mock.program(), direction: .vertical)
            .previewLayout(.fixed(width: 500, height: 105))
        ProgramCell(program: Mock.program(), direction: .vertical)
            .previewLayout(.fixed(width: 80, height: 105))
    }
}
