//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import NukeUI
import SwiftUI

// MARK: View

// Behavior: h-exp, v-hug
struct ProgramView: View {
    @Binding var data: ProgramAndChannel
    @StateObject private var model = ProgramViewModel()

    static func viewController(for program: PlayProgram, channel: PlayChannel) -> UIViewController {
        ProgramViewController(program: program, channel: channel)
    }

    init(program: PlayProgram, channel: PlayChannel) {
        _data = .constant(.init(program: program, channel: channel))
    }

    var body: some View {
        VStack(spacing: 18) {
            Handle {
                guard let viewController = UIApplication.shared.mainTopViewController else { return }
                viewController.dismiss(animated: true)
            }
            ScrollView {
                VStack(spacing: 16) {
                    InteractiveVisualView(model: model)
                        .aspectRatio(16 / 9, contentMode: .fit)
                        .cornerRadius(LayoutStandardViewCornerRadius)
                        .accessibilityElement(label: accessibilityLabel, traits: accessibilityTraits)
                    TitleView(model: model)
                    if model.hasActions {
                        ActionsView(model: model)
                            .padding(.vertical, 8)
                    }
                    AdditionnalInformationView(model: model)
                    DescriptionView(model: model)
                    if let crewMembersDatas = model.crewMembersDatas {
                        CrewMembersView(datas: crewMembersDatas)
                    }
                    if let properties = model.showButtonProperties {
                        ShowButton(show: properties.show, isFavorite: properties.isFavorite, action: properties.action)
                    }
                    Spacer()
                }
            }
        }
        .padding(.horizontal, 14)
        .onAppear {
            model.data = data
        }
        .onChange(of: data) { newValue in
            model.data = newValue
        }
    }

    // Behavior: h-exp, v-exp
    private struct InteractiveVisualView: View {
        @ObservedObject var model: ProgramViewModel

        var body: some View {
            Group {
                if let action = model.playAction {
                    Button(action: action) {
                        ZStack {
                            VisualView(model: model)
                            Color(white: 0, opacity: 0.2)
                            Image(ImageResource.play)
                                .foregroundColor(.white)
                        }
                    }
                } else {
                    VisualView(model: model)
                }
            }
        }
    }

    // Behavior: h-exp, v-exp
    private struct VisualView: View {
        @ObservedObject var model: ProgramViewModel

        static let padding: CGFloat = 6

        var body: some View {
            ZStack {
                ImageView(source: model.imageUrl)
                    .background(Color.thumbnailBackground)
                BlockingOverlay(media: model.currentMedia, messageDisplayed: true)

                if let progress = model.progress {
                    ProgressBar(value: progress)
                        .frame(height: LayoutProgressBarHeight)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                }
            }
        }
    }

    // Behavior: h-exp, v-hug
    private struct ActionsView: View {
        @ObservedObject var model: ProgramViewModel
        @Environment(\.uiHorizontalSizeClass) private var horizontalSizeClass

        static let buttonHeight: CGFloat = 40

        private var direction: StackDirection {
            horizontalSizeClass == .compact ? .vertical : .horizontal
        }

        var body: some View {
            Stack(direction: direction, spacing: 8) {
                if let properties = model.watchLaterButtonProperties {
                    ExpandingButton(icon: properties.icon, label: properties.label, action: properties.action)
                        .frame(height: Self.buttonHeight)
                }
                if let properties = model.watchFromStartButtonProperties {
                    ExpandingButton(icon: properties.icon, label: properties.label, action: properties.action)
                        .frame(height: Self.buttonHeight)
                }
                if let properties = model.calendarButtonProperties {
                    ExpandingButton(icon: properties.icon, label: properties.label, action: properties.action)
                        .frame(height: Self.buttonHeight)
                }
            }
        }
    }

    // Behavior: h-exp, v-hug
    private struct YouthProtectionView: View {
        let color: SRGYouthProtectionColor

        init(color: SRGYouthProtectionColor) {
            self.color = color
        }

        var body: some View {
            HStack(spacing: 8) {
                YouthProtectionBadge(color: color)
                if let youthProtectionMessage = SRGMessageForYouthProtectionColor(color) {
                    Text(youthProtectionMessage)
                        .srgFont(.subtitle1)
                        .lineLimit(2)
                        .foregroundColor(.srgGray96)
                }
            }
            .accessibilityElement(label: SRGMessageForYouthProtectionColor(color))
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // Behavior: h-exp, v-hug
    private struct AdditionnalInformationView: View {
        @ObservedObject var model: ProgramViewModel

        var body: some View {
            VStack(spacing: 8) {
                if let durationAndProduction = model.durationAndProduction {
                    Text(durationAndProduction)
                        .srgFont(.subtitle1)
                        .lineLimit(1)
                        .foregroundColor(.srgGray96)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                if let youthProtectionColor = model.youthProtectionColor {
                    YouthProtectionView(color: youthProtectionColor)
                }
            }
        }
    }

    // Behavior: h-exp, v-hug
    private struct CrewMembersView: View {
        let crewMembersDatas: [ProgramViewModel.CrewMembersData]

        init(datas: [ProgramViewModel.CrewMembersData]) {
            crewMembersDatas = datas
        }

        var body: some View {
            VStack(alignment: .leading, spacing: 18) {
                ForEach(crewMembersDatas) { crewMembersData in
                    VStack(alignment: .leading, spacing: 0) {
                        if let role = crewMembersData.role {
                            Text(role)
                                .srgFont(.H2)
                                .foregroundColor(.srgGray96)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(crewMembersData.names, id: \.self) { name in
                                Text(name)
                                    .srgFont(.body)
                                    .foregroundColor(.srgGray96)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    }
                    .accessibilityElement(label: crewMembersData.accessibilityLabel)
                }
            }
        }
    }

    // Behavior: h-exp, v-hug
    private struct DescriptionView: View {
        @ObservedObject var model: ProgramViewModel

        var body: some View {
            VStack(spacing: 8) {
                if let lead = model.lead {
                    Text(lead)
                        .srgFont(.H4)
                        .foregroundColor(.srgGray96)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                if let summary = model.summary {
                    Text(summary)
                        .srgFont(.body)
                        .foregroundColor(.srgGray96)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                if let imageCopyright = model.imageCopyright {
                    Text(imageCopyright)
                        .srgFont(.subtitle1)
                        .foregroundColor(.srgGray96)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                if let badgesListData = model.badgesListData {
                    BadgeList(data: badgesListData)
                }
            }
        }
    }

    // Behavior: h-hug, v-hug
    private struct TitleView: View {
        @ObservedObject var model: ProgramViewModel

        var body: some View {
            VStack(spacing: 8) {
                if let properties = model.availabilityBadgeProperties {
                    Badge(text: properties.text, color: Color(properties.color))
                }
                VStack(spacing: 0) {
                    if let timeAndDate = model.timeAndDate {
                        Text(timeAndDate)
                            .srgFont(.caption)
                            .lineLimit(1)
                            .foregroundColor(.srgGray96)
                            .accessibilityElement(label: model.timeAndDateAccessibilityLabel)
                    }
                    if let title = model.title {
                        Text(title)
                            .srgFont(.H2)
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.srgGrayD2)
                    }
                    if let subtitle = model.subtitle {
                        Text(subtitle)
                            .srgFont(.subtitle1)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.srgGray96)
                    }
                    if let serie = model.serie {
                        Text(serie)
                            .srgFont(.caption)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.srgGray96)
                            .padding(.top, 4)
                    }
                }
            }
        }
    }
}

// MARK: View controller

private final class ProgramViewController: UIHostingController<ProgramView> {
    init(program: PlayProgram, channel: PlayChannel) {
        super.init(rootView: ProgramView(program: program, channel: channel))
    }

    @available(*, unavailable)
    @MainActor dynamic required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: Accessibility

private extension ProgramView {
    var accessibilityLabel: String? {
        model.playAction != nil ? PlaySRGAccessibilityLocalizedString("Play", comment: "Play button label") : nil
    }

    var accessibilityTraits: AccessibilityTraits {
        .isButton
    }
}

// MARK: Preview

struct ProgramView_Previews: PreviewProvider {
    private static let size = CGSize(width: 320, height: 1200)

    static var previews: some View {
        Group {
            ProgramView(program: Mock.playProgram(), channel: Mock.playChannel())
            ProgramView(program: Mock.playProgram(.overflow), channel: Mock.playChannel())
            ProgramView(program: Mock.playProgram(.fallbackImageUrl), channel: Mock.playChannel())
        }
        .previewLayout(.fixed(width: size.width, height: size.height))
    }
}
