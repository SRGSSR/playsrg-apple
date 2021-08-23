//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

// MARK: View

// Behavior: h-exp, v-hug
struct ProgramView: View {
    @Binding var data: ProgramViewModel.Data
    @StateObject private var model = ProgramViewModel()
    
    static func viewController(for program: SRGProgram, channel: SRGChannel) -> UIViewController {
        return ProgramViewController(program: program, channel: channel)
    }
    
    init(program: SRGProgram, channel: SRGChannel) {
        _data = .constant(.init(program: program, channel: channel))
    }
    
    var body: some View {
        VStack(spacing: 18) {
            Handle()
            ScrollView {
                VStack(spacing: 10) {
                    InteractiveVisualView(model: model)
                        .aspectRatio(16 / 9, contentMode: .fit)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(LayoutStandardViewCornerRadius)
                        .accessibilityElement(label: accessibilityLabel, traits: accessibilityTraits)
                    DescriptionView(model: model)
                    Spacer()
                }
            }
        }
        .padding([.horizontal, .top], 14)
        .onAppear {
            model.data = data
        }
        .onChange(of: data) { newValue in
            model.data = newValue
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
                            Image("play")
                                .foregroundColor(.white)
                        }
                    }
                }
                else {
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
                ImageView(url: model.imageUrl)
                BlockingOverlay(media: model.currentMedia, messageDisplayed: true)
                
                if let properties = model.availabilityBadgeProperties {
                    Badge(text: properties.text, color: Color(properties.color))
                        .padding([.top, .leading], Self.padding)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                }
                
                HStack(spacing: 6) {
                    Spacer()
                    if model.hasMultiAudio {
                        MultiAudioBadge()
                    }
                    if model.hasAudioDescription {
                        AudioDescriptionBadge()
                    }
                    if model.hasSubtitles {
                        SubtitlesBadge()
                    }
                    if let duration = model.duration {
                        DurationBadge(duration: duration)
                    }
                }
                .padding([.bottom, .horizontal], Self.padding)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                
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
        
        var body: some View {
            HStack(spacing: 7) {
                if let properties = model.watchLaterButtonProperties {
                    ExpandingButton(icon: properties.icon, label: properties.label, action: properties.action)
                }
                if let properties = model.watchFromStartButtonProperties {
                    ExpandingButton(icon: properties.icon, label: properties.label, action: properties.action)
                }
                if let properties = model.episodeButtonProperties {
                    ExpandingButton(icon: properties.icon, label: properties.label, action: properties.action)
                }
            }
            .frame(height: 40)
        }
    }
    
    // Behavior: h-exp, v-hug
    private struct DescriptionView: View {
        @ObservedObject var model: ProgramViewModel
        
        var body: some View {
            VStack(spacing: 18) {
                VStack(spacing: 6) {
                    if let timeAndDate = model.timeAndDate {
                        Text(timeAndDate)
                            .srgFont(.caption)
                            .lineLimit(1)
                            .foregroundColor(.srgGray96)
                            .accessibilityElement(label: model.timeAndDateAccessibilityLabel)
                    }
                    TitleView(model: model)
                }
                
                if model.hasActions {
                    ActionsView(model: model)
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
            }
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
                        .multilineTextAlignment(.center)
                        .foregroundColor(.srgGray96)
                }
            }
        }
    }
}

// MARK: View controller

private final class ProgramViewController: UIHostingController<ProgramView> {
    init(program: SRGProgram, channel: SRGChannel) {
        super.init(rootView: ProgramView(program: program, channel: channel))
    }
    
    @objc required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return Self.play_supportedInterfaceOrientations
    }
}

// MARK: Accessibility

extension ProgramView {
    var accessibilityLabel: String? {
        return model.playAction != nil ? PlaySRGAccessibilityLocalizedString("Play", comment: "Play button label") : nil
    }
    
    var accessibilityTraits: AccessibilityTraits {
        return .isButton
    }
}

// MARK: Preview

struct ProgramView_Previews: PreviewProvider {
    private static let size = CGSize(width: 320, height: 600)
    
    static var previews: some View {
        ProgramView(program: Mock.program(), channel: Mock.channel())
            .previewLayout(.fixed(width: size.width, height: size.height))
    }
}