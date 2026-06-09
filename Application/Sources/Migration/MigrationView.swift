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

    let isMigrationMandatory: Bool

    var body: some View {
        VStack(spacing: 24) {
            Image(.playPlusAppIcon)

            Text(appConfiguration.migrationScreenTitle)
            Text(appConfiguration.migrationScreenDescription)

            Button(appConfiguration.migrationScreenPrimaryAction) {
                print("Primary Action")
            }

            Button(appConfiguration.migrationScreenSecondaryAction) {
                print("Secondary Action")
            }
        }
    }
}

// MARK: Objective-C bridge

@objc final class MigrationViewController: NSObject {
    @objc static func viewController(isMigrationMandatory: Bool) -> UIViewController {
        let controller = UIHostingController(rootView: MigrationView(isMigrationMandatory: isMigrationMandatory))
        controller.modalPresentationStyle = .fullScreen
        return controller
    }
}

#Preview {
    MigrationView(isMigrationMandatory: false)
}
