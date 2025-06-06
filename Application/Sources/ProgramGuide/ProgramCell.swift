//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGAppearanceSwift
import SwiftUI

// MARK: Cell

struct ProgramCell: View {
    @Binding var data: ProgramAndChannel
    let direction: StackDirection

    @StateObject private var model = ProgramCellViewModel()

    @Environment(\.isSelected) private var isSelected

    init(program: PlayProgram, channel: PlayChannel, direction: StackDirection) {
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
            direction == .horizontal ? timeRangeFixedWidth : .infinity
        }

        private var timeRangeLineLimit: Int {
            direction == .horizontal ? 2 : 1
        }

        private var alignment: StackAlignment {
            direction == .horizontal ? .center : .leading
        }

        private var horizontalPadding: CGFloat {
            direction == .horizontal ? 16 : 12
        }

        private var verticalPadding: CGFloat {
            direction == .horizontal ? 0 : constant(iOS: 4, tvOS: 8)
        }

        private var spacing: CGFloat {
            direction == .horizontal ? 10 : constant(iOS: 4, tvOS: 0)
        }

        private var isCompact: Bool {
            availableSize.width < 100
        }

        private var isDisplayable: Bool {
            availableSize.width > 2 * horizontalPadding + 5
        }

        var body: some View {
            ZStack {
                Stack(direction: direction, alignment: alignment, spacing: spacing) {
                    if isDisplayable {
                        if let timeRange = model.timeRange {
                            Text(timeRange)
                                .srgFont(.subtitle2)
                                .lineLimit(timeRangeLineLimit)
                                .foregroundColor(.srgGray96)
                                .frame(maxWidth: timeRangeWidth, alignment: .leading)
                        }
                        TitleView(model: model, compact: isCompact)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        Color.clear
                    }
                }
                .padding(.horizontal, isDisplayable ? horizontalPadding : 0)
                .padding(.vertical, verticalPadding)
                .frame(maxHeight: .infinity)
                .background(!isFocused ? Color.srgGray23 : Color.srgGray33)

                if direction == .horizontal, let progress = model.progress {
                    ProgressBar(value: progress)
                        .frame(height: LayoutProgressBarHeight)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                }
            }
            .cornerRadius(4)
            .readSize { size in
                availableSize = size
            }
        }
    }

    /// Behavior: h-hug, v-hug
    private struct TitleView: View {
        @ObservedObject var model: ProgramCellViewModel
        let compact: Bool

        private let canPlayHeight: CGFloat = 24

        var body: some View {
            HStack(spacing: 10) {
                if !compact, model.canPlay {
                    Image(.playCircle)
                        .foregroundColor(.srgGrayD2)
                        .frame(height: canPlayHeight)
                }
                if let title = model.title {
                    Text(title)
                        .srgFont(.body)
                        .lineLimit(1)
                        .foregroundColor(.srgGrayD2)
                }
            }
            .frame(minHeight: canPlayHeight)
        }
    }
}

// MARK: Accessibility

private extension ProgramCell {
    var accessibilityLabel: String? {
        model.accessibilityLabel
    }

    var accessibilityHint: String? {
        PlaySRGAccessibilityLocalizedString("Opens details.", comment: "Program cell hint")
    }
}

// MARK: Size

enum ProgramCellSize {
    static func fullWidth() -> NSCollectionLayoutSize {
        NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(50))
    }
}

// MARK: Preview

struct ProgramCell_Previews: PreviewProvider {
    private static let size = ProgramCellSize.fullWidth().previewSize
    private static let height: CGFloat = constant(iOS: 80, tvOS: 120)

    static var previews: some View {
        ProgramCell(program: Mock.playProgram(), channel: Mock.playChannel(), direction: .horizontal)
            .previewLayout(.fixed(width: size.width, height: size.height))
            .background(Color.white)
            .previewDisplayName("horizontal")
        ProgramCell(program: Mock.playProgram(), channel: Mock.playChannel(), direction: .vertical)
            .previewLayout(.fixed(width: 500, height: height))
            .background(Color.white)
            .previewDisplayName("vertical, w 500")
        ProgramCell(program: Mock.playProgram(), channel: Mock.playChannel(), direction: .vertical)
            .previewLayout(.fixed(width: 80, height: height))
            .background(Color.white)
            .previewDisplayName("vertical, w 80")
        ProgramCell(program: Mock.playProgram(), channel: Mock.playChannel(), direction: .vertical)
            .previewLayout(.fixed(width: 40, height: height))
            .background(Color.white)
            .previewDisplayName("vertical, w 40")
        ProgramCell(program: Mock.playProgram(), channel: Mock.playChannel(), direction: .vertical)
            .previewLayout(.fixed(width: 30, height: height))
            .background(Color.white)
            .previewDisplayName("vertical, w 30")
        ProgramCell(program: Mock.playProgram(), channel: Mock.playChannel(), direction: .vertical)
            .previewLayout(.fixed(width: 24, height: height))
            .background(Color.white)
            .previewDisplayName("vertical, w 24")
        ProgramCell(program: Mock.playProgram(), channel: Mock.playChannel(), direction: .vertical)
            .previewLayout(.fixed(width: 20, height: height))
            .background(Color.white)
            .previewDisplayName("vertical, w 20")
        ProgramCell(program: Mock.playProgram(), channel: Mock.playChannel(), direction: .vertical)
            .previewLayout(.fixed(width: 10, height: height))
            .background(Color.white)
            .previewDisplayName("vertical, w 10")
        ProgramCell(program: Mock.playProgram(), channel: Mock.playChannel(), direction: .vertical)
            .previewLayout(.fixed(width: 1, height: height))
            .background(Color.white)
            .previewDisplayName("vertical, w 1")
    }
}
