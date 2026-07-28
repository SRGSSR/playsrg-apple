//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGAppearanceSwift
import SwiftUI

struct MigrationView: View {
    private let appConfiguration = ApplicationConfiguration.shared

    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack(spacing: 88) {
            appIconView

            VStack(spacing: 24) {
                Text("This app no longer exists")
                    .srgFont(family: .text, weight: .srg_bold, fixedSize: 64)

                Text("This app has been replaced by Play+. You can now update or re-download the Play+ app. All your data will be retained.")
                    .srgFont(family: .text, weight: .srg_medium, fixedSize: 24)

                Button("Update now") {
                    openURL(appConfiguration.tvPlayPlusStoreURL)
                }
                .buttonStyle(MigrationPrimaryButtonStyle())
            }
            .multilineTextAlignment(.center)
        }
        .frame(width: 544)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(backgroundView)
    }

    private var appIconView: some View {
        Image(.playPlusAppIcon)
            .resizable()
            .frame(width: 224, height: 224)
            .shadow(color: .white, radius: 180, x: 0, y: 0)
            .shadow(
                color: Color(red: 1, green: 0.82, blue: 0.82).opacity(0.7),
                radius: 83,
                x: 0,
                y: 0
            )
    }

    private var backgroundView: some View {
        Image(.migrationBackground)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .ignoresSafeArea()
    }
}

private struct MigrationPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .srgFont(family: .text, weight: .srg_bold, fixedSize: 32)
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .padding(.horizontal, 24)
            .background(Color.white)
            .clipShape(.capsule)
            .opacity(configuration.isPressed ? 0.8 : 1)
    }
}

#Preview {
    MigrationView()
}
