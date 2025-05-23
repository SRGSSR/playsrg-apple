//
//  SupportFormView.swift
//  PlaySRG
//
//  Created by Yoan Smit on 23.05.2025.
//  Copyright © 2025 SRG SSR. All rights reserved.
//

import CoreImage.CIFilterBuiltins
import SwiftUI

struct SupportFormView: View {
    let formURL: URL

    var body: some View {
        GeometryReader { geometry in
            VStack {
                Text("Scan this code to send a feedback or contact support")
                    .srgFont(.H1)
                    .padding([.horizontal, .top])

                Spacer()

                if let qrCodeImage = generateQRCode() {
                    Image(uiImage: qrCodeImage)
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                        .frame(width: geometry.size.width / 4)
                } else {
                    if #available(tvOS 17.0, *) {
                        ContentUnavailableView(
                            "Unable to generate QR code",
                            systemImage: "xmark.circle"
                        )
                    } else {
                        Label("Unable to generate QR code", systemImage: "xmark.circle")
                    }
                }

                Spacer()
            }
            .frame(width: geometry.size.width)
        }
    }

    private func generateQRCode() -> UIImage? {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()

        filter.message = Data(formURL.absoluteString.utf8)

        guard
            let outputImage = filter.outputImage,
            let cgImage = context.createCGImage(outputImage, from: outputImage.extent)
        else {
            return nil
        }

        return UIImage(cgImage: cgImage)
    }
}

#Preview {
    SupportFormView(formURL: URL(string: "www.google.com")!)
}
