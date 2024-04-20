//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

// MARK: View

/// Behavior: h-exp, v-exp
struct TopicGradientView: View {
    enum Style {
    case topicPage
    case showPage
    }
    
    let topic: SRGTopic
    let style: Style
    let verticallyCentered: Bool
    
    init(_ topic: SRGTopic, style: Style, verticallyCentered: Bool = false) {
        self.topic = topic
        self.style = style
        self.verticallyCentered = verticallyCentered
    }
    
    var body: some View {
        if let topicColors = ApplicationConfiguration.shared.topicColors(for: topic) {
            ZStack {
                RadialColorGradient(
                    topicColors: topicColors,
                    opacity: opacity,
                    verticallyCentered: verticallyCentered
                )
                LinearGreyGradient(
                    verticallyCentered: verticallyCentered
                )
            }
        } else {
            Color.clear
        }
    }
    
    /// Behavior: h-exp, v-exp
    private struct RadialColorGradient: View {
        let topicColors: (Color, Color)
        let opacity: Double
        let verticallyCentered: Bool
        
        private var centerY: CGFloat {
            return verticallyCentered ? 0.5 : 0
        }
        
        var body: some View {
            GeometryReader { geometry in
                RadialGradient(
                    gradient: Gradient(stops: [
                        Gradient.Stop(color: topicColors.0.opacity(opacity), location: 0),
                        Gradient.Stop(color: topicColors.1.opacity(opacity), location: 0.8)
                    ]),
                    center: UnitPoint(x: 0.5, y: centerY),
                    startRadius: 0,
                    endRadius: geometry.size.width
                )
            }
        }
    }
    
    /// Behavior: h-exp, v-exp
    private struct LinearGreyGradient: View {
        let verticallyCentered: Bool
        
        private var startPointY: CGFloat {
            return verticallyCentered ? 0.5 : 0
        }
        
        var body: some View {
            LinearGradient(
                colors: [.clear, .srgGray16],
                startPoint: UnitPoint(x: 0.5, y: startPointY),
                endPoint: .bottom
            )
        }
    }
    
    private var opacity: Double {
        switch style {
        case .topicPage:
            return 0.1 /* Official 0.7 needs work on font colors for contrast */
        case .showPage:
            return 0.2
        }
    }
}

// MARK: Preview

struct TopicGradientView_Previews: PreviewProvider {
    private struct PreviewView<Content: View>: View {
        @ViewBuilder var content: () -> Content
        
        var body: some View {
            ZStack {
                Rectangle()
                    .fill(Color.srgGray16)
                content()
            }
        }
    }
    
    static var previews: some View {
        Group {
            PreviewView {
                TopicGradientView(Mock.topic(), style: .topicPage)
            }
            PreviewView {
                TopicGradientView(Mock.topic(), style: .showPage)
            }
            PreviewView {
                TopicGradientView(Mock.topic(), style: .showPage, verticallyCentered: true)
            }
            PreviewView {
                TopicGradientView(Mock.topic(.overflow), style: .topicPage)
            }
        }
        .previewLayout(.fixed(width: 400, height: 572))
        
        Group {
            PreviewView {
                TopicGradientView(Mock.topic(), style: .topicPage)
            }
            PreviewView {
                TopicGradientView(Mock.topic(), style: .showPage)
            }
            PreviewView {
                TopicGradientView(Mock.topic(), style: .showPage, verticallyCentered: true)
            }
            PreviewView {
                TopicGradientView(Mock.topic(.overflow), style: .topicPage)
            }
        }
        .previewLayout(.fixed(width: 1080, height: 572))
    }
}
