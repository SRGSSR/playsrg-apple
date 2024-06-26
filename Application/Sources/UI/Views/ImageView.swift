//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import Nuke
import NukeUI
import SwiftUI

// MARK: View

/**
 *  An image view supporting content modes for image scaling and alignment.
 *
 *  Remark: This cannot be implemented with Nuke resizing processors because the image size is usually not reliably known
 *          when SwiftUI builds the view for the first time. Instead we use SwiftUI frames to size the content and position
 *          it afterwards.
 *
 *  Behavior: h-exp, v-exp
 */
struct ImageView: View {
    enum ContentMode {
        case aspectFit
        case aspectFill
        case center
        case fill
        case top
        case bottom
        case left
        case right
        case topLeft
        case topRight
        case bottomLeft
        case bottomRight
        case aspectFitTop
        case aspectFitBottom
        case aspectFitLeft
        case aspectFitRight
        case aspectFitTopLeft
        case aspectFitTopRight
        case aspectFitBottomLeft
        case aspectFitBottomRight
        case aspectFillTop
        case aspectFillBottom
        case aspectFillLeft
        case aspectFillRight
        case aspectFillTopLeft
        case aspectFillTopRight
        case aspectFillBottomLeft
        case aspectFillBottomRight
        case aspectFillFocused(relativeWidth: CGFloat, relativeHeight: CGFloat)
    }

    let source: ImageRequestConvertible?
    let contentMode: ContentMode

    private static func alignment(for contentMode: Self.ContentMode) -> Alignment {
        switch contentMode {
        case .aspectFit, .aspectFill, .center, .fill, .aspectFillFocused:
            .center
        case .top, .aspectFitTop, .aspectFillTop:
            .top
        case .bottom, .aspectFitBottom, .aspectFillBottom:
            .bottom
        case .left, .aspectFitLeft, .aspectFillLeft:
            .leading
        case .right, .aspectFitRight, .aspectFillRight:
            .trailing
        case .topLeft, .aspectFitTopLeft, .aspectFillTopLeft:
            .topLeading
        case .topRight, .aspectFitTopRight, .aspectFillTopRight:
            .topTrailing
        case .bottomLeft, .aspectFitBottomLeft, .aspectFillBottomLeft:
            .bottomLeading
        case .bottomRight, .aspectFitBottomRight, .aspectFillBottomRight:
            .bottomTrailing
        }
    }

    private static func fitSize(for imageContainer: ImageContainer, in geometry: GeometryProxy) -> CGSize {
        let imageSize = imageContainer.image.size
        guard imageSize.width != 0, imageSize.height != 0 else { return .zero }

        let targetSize = geometry.size
        guard targetSize.width != 0, targetSize.height != 0 else { return .zero }

        let imageAspectRatio = imageSize.width / imageSize.height
        let targetAspectRatio = targetSize.width / targetSize.height

        if targetAspectRatio > imageAspectRatio {
            return CGSize(width: targetSize.height * imageAspectRatio, height: targetSize.height)
        } else {
            return CGSize(width: targetSize.width, height: targetSize.width / imageAspectRatio)
        }
    }

    private static func fillSize(for imageContainer: ImageContainer, in geometry: GeometryProxy) -> CGSize {
        let imageSize = imageContainer.image.size
        guard imageSize.width != 0, imageSize.height != 0 else { return .zero }

        let targetSize = geometry.size
        guard targetSize.width != 0, targetSize.height != 0 else { return .zero }

        let imageAspectRatio = imageSize.width / imageSize.height
        let targetAspectRatio = targetSize.width / targetSize.height

        if targetAspectRatio > imageAspectRatio {
            return CGSize(width: targetSize.width, height: targetSize.width / imageAspectRatio)
        } else {
            return CGSize(width: targetSize.height * imageAspectRatio, height: targetSize.height)
        }
    }

    /**
     *  Calculate the offset to apply so that the focal point P approaches the center C of the target frame as close as
     *  possible while ensuring the resized filling image entirely covers the target frame.
     *
     *    ┌─────────────────┬─────────────────────────────────────────┬────────────────────┐
     *    │                 │                                         │                    │
     *    │                 │  Target frame                           │                    │
     *    │                 │                                         │                    │
     *    │                 │                                         │                    │
     *    │                 │                                         │            P       │
     *    │                 │                                         │                    │
     *    │                 │                                         │                    │
     *    │                 │                                         │                    │
     *    │                 │                                         │                    │
     *    │                 │                                         │                    │
     *    │                 │                    C                    │                    │
     *    │                 │                                         │                    │
     *    │                 │                                         │                    │
     *    │                 │                                         │                    │
     *    │                 │                                         │                    │
     *    │                 │                                         │                    │
     *    │                 │                                         │                    │
     *    │                 │                                         │                    │
     *    │                 │                                         │                    │
     *    │                 │                                         │                    │
     *    └─────────────────┴─────────────────────────────────────────┴────────────────────┘
     *
     *                                                                     Resized frame
     */
    private static func offset(forFocalPoint focalPoint: CGPoint, targetSize: CGSize, fillSize: CGSize) -> CGSize {
        let margins = CGSize(
            width: (fillSize.width - targetSize.width) / 2,
            height: (fillSize.height - targetSize.height) / 2
        )
        return CGSize(
            width: -(focalPoint.x - fillSize.width / 2).clamped(to: -margins.width ... margins.width),
            height: (focalPoint.y - fillSize.height / 2).clamped(to: -margins.height ... margins.height)
        )
    }

    init(source: ImageRequestConvertible?, contentMode: ContentMode = .aspectFit) {
        self.source = source
        self.contentMode = contentMode
    }

    var body: some View {
        GeometryReader { geometry in
            LazyImage(source: source) { state in
                if let image = state.image, let imageContainer = state.imageContainer {
                    switch contentMode {
                    case .aspectFit:
                        image
                            .resizingMode(.aspectFit)
                    case .aspectFill:
                        image
                            .resizingMode(.aspectFill)
                    case .center:
                        image
                            .resizingMode(.center)
                    case .fill:
                        image
                            .resizingMode(.fill)
                    case .top, .bottom, .left, .right,
                         .topLeft, .topRight, .bottomLeft, .bottomRight:
                        image
                            .frame(size: imageContainer.image.size)
                            .frame(size: geometry.size, alignment: Self.alignment(for: contentMode))
                    case .aspectFitTop, .aspectFitBottom, .aspectFitLeft, .aspectFitRight,
                         .aspectFitTopLeft, .aspectFitTopRight, .aspectFitBottomLeft, .aspectFitBottomRight:
                        image
                            .resizingMode(.fill)
                            .frame(size: Self.fitSize(for: imageContainer, in: geometry))
                            .frame(size: geometry.size, alignment: Self.alignment(for: contentMode))
                    case .aspectFillTop, .aspectFillBottom, .aspectFillLeft, .aspectFillRight,
                         .aspectFillTopLeft, .aspectFillTopRight, .aspectFillBottomLeft, .aspectFillBottomRight:
                        image
                            .resizingMode(.fill)
                            .frame(size: Self.fillSize(for: imageContainer, in: geometry))
                            .frame(size: geometry.size, alignment: Self.alignment(for: contentMode))
                    case let .aspectFillFocused(relativeWidth: relativeWidth, relativeHeight: relativeHeight):
                        let fillSize = Self.fillSize(for: imageContainer, in: geometry)
                        let targetSize = geometry.size
                        let focalPoint = CGPoint(x: fillSize.width * relativeWidth, y: fillSize.height * relativeHeight)
                        image
                            .resizingMode(.fill)
                            .frame(size: fillSize)
                            .frame(size: targetSize, alignment: Self.alignment(for: contentMode))
                            .offset(Self.offset(forFocalPoint: focalPoint, targetSize: targetSize, fillSize: fillSize))
                    }
                } else {
                    Color.placeholder
                }
            }
            .clipped()
        }
    }
}

// MARK: Preview

struct ImageView_Previews: PreviewProvider {
    static var previews: some View {
        ImageView(source: "https://www.rts.ch/2020/11/09/11/29/11737826.image/16x9/scale/width/400")
            .previewLayout(.fixed(width: 1000, height: 1000))
    }
}
