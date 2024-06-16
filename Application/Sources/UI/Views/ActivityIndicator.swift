//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

// Remark: It would be tempting to animate the view with SwiftUI directly (by animating its rotation angle, see for
//         example https://sarunw.com/posts/animation-delay-and-repeatforever-in-swiftui/), but the animation hangs
//         for a while at application startup for some reason. For the moment we simply wrap the animated view we have
//         for a reliable result.
struct ActivityIndicator: View {
    var body: some View {
        LoadingImageView()
            .frame(width: 90, height: 90)
    }

    private struct LoadingImageView: UIViewRepresentable {
        func makeUIView(context _: Context) -> UIImageView {
            return UIImageView.play_largeLoadingImageView(withTintColor: .srgGrayD2)
        }

        func updateUIView(_: UIImageView, context _: Context) {
            // No update logic required
        }
    }
}

struct ActivityIndicator_Previews: PreviewProvider {
    static var previews: some View {
        ActivityIndicator()
            .previewLayout(.sizeThatFits)
    }
}
