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
        VStack(spacing: 24) {
            Image(.playPlusAppIcon)

            Text(appConfiguration.migrationScreenTitle)
            Text(appConfiguration.migrationScreenDescription)

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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            Image(.migrationBackground)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .ignoresSafeArea()
        )
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
