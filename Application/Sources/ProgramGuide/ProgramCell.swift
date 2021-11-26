//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGAppearanceSwift
import SwiftUI

// MARK: Cell

struct ProgramCell: View {
    @Binding var data: ProgramCellViewModel.Data
    let direction: StackDirection
    
    @StateObject private var model = ProgramCellViewModel()
    
    @Environment(\.isSelected) private var isSelected
    
    init(program: SRGProgram, channel: SRGChannel?, direction: StackDirection) {
        _data = .constant(.init(program: program, channel: channel))
        self.direction = direction
    }
    
    var body: some View {
        Group {
#if os(tvOS)
            MainView(model: model, direction: direction)
#else
            MainView(model: model, direction: direction)
                .selectionAppearance(.dimmed, when: isSelected)
                .accessibilityElement(label: accessibilityLabel, hint: accessibilityHint)
#endif
        }
        .onAppear {
            model.data = data
        }
        .onChange(of: data) { newValue in
            model.data = newValue
        }
    }
        
    /// Behavior: h-exp, v-exp
    private struct MainView: View {
        @ObservedObject var model: ProgramCellViewModel
        let direction: StackDirection
        
        @SRGScaledMetric var timeRangeFixedWidth: CGFloat = 90
        @State private var availableSize: CGSize = .zero
        @Environment(\.isUIKitFocused) private var isFocused
        
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
            return direction == .horizontal ? 16 : 12
        }
        
        private var topPadding: CGFloat {
            return direction == .horizontal ? 0 : constant(iOS: 27, tvOS: 16)
        }
        
        private var bottomPadding: CGFloat {
            return direction == .horizontal ? 0 : constant(iOS: 4, tvOS: 8)
        }
        
        private var spacing: CGFloat {
            return direction == .horizontal ? 10 : constant(iOS: 4, tvOS: 0)
        }
        
        private var isCompact: Bool {
            return availableSize.width < 100
        }
        
        var body: some View {
            ZStack {
                Stack(direction: direction, alignment: alignment, spacing: spacing) {
                    if let timeRange = model.timeRange {
                        Text(timeRange)
                            .srgFont(.subtitle2)
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
                if let title = model.data?.program.title {
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
    private static let height: CGFloat = constant(iOS: 105, tvOS: 120)
    
    static var previews: some View {
        ProgramCell(program: Mock.program(), channel: Mock.channel(), direction: .horizontal)
            .previewLayout(.fixed(width: size.width, height: size.height))
        ProgramCell(program: Mock.program(), channel: Mock.channel(), direction: .vertical)
            .previewLayout(.fixed(width: 500, height: height))
        ProgramCell(program: Mock.program(), channel: Mock.channel(), direction: .vertical)
            .previewLayout(.fixed(width: 80, height: height))
    }
}
