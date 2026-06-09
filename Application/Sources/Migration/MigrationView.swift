//
//  MigrationView.swift
//  Play SRF
//
//  Created by Yoan Smit on 08.06.2026.
//  Copyright © 2026 SRG SSR. All rights reserved.
//

import SwiftUI

struct MigrationView: View {
    private let appConfiguration = ApplicationConfiguration.shared

    var body: some View {
        VStack(spacing: .zero) {
            VStack(spacing: 24) {
                Image(.playPlusAppIcon)
                    .resizable()
                    .frame(width: 120, height: 120)

                Text(appConfiguration.migrationScreenTitle)
                    .srgFont(family: .text, weight: .srg_bold, fixedSize: 32)

                Text(appConfiguration.migrationScreenDescription)
                    .srgFont(family: .text, weight: .srg_medium, fixedSize: 14)
            }
            .multilineTextAlignment(.center)
            .frame(maxHeight: .infinity)

            Group {
                if #available(iOS 17, *) {
                    Button(appConfiguration.migrationScreenPrimaryAction) {
                        print("Primary Action")
                    }
                } else {
                    Button(appConfiguration.migrationScreenSecondaryAction) {
                        print("Secondary Action")
                    }
                }
            }
            .buttonStyle(MigrationPrimaryButtonStyle())
        }
        .padding(.horizontal, 28)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            Image(.migrationBackground)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .ignoresSafeArea()
        )
    }
}

private struct MigrationPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .srgFont(family: .text, weight: .srg_bold, fixedSize: 16)
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .padding(.horizontal, 32)
            .background(Color.white)
            .clipShape(Capsule())
            .opacity(configuration.isPressed ? 0.8 : 1)
    }
}

// MARK: Objective-C bridge

@objc final class MigrationViewController: NSObject {
    @objc static func viewController() -> UIViewController {
        UIHostingController(rootView: MigrationView())
    }
}

#Preview {
    MigrationView()
}
