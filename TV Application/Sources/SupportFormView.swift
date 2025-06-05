//
//  Copyright © SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import CoreImage.CIFilterBuiltins
import SwiftUI

struct SupportFormView: View {
    let formURL: URL

    var body: some View {
        GeometryReader { geometry in
            Text(NSLocalizedString("Support and Feedback", comment: "Title of the screen showing the QR code to send a feedback or contact support"))
                .srgFont(.H1)
                .padding()
                .frame(maxWidth: .infinity, alignment: .center)
            HStack(alignment: .center) {
                Spacer()

                VStack {
                    Text(NSLocalizedString("Contact support / Make a suggestion", comment: "Subtitle of the screen showing the QR code to send a feedback or contact support"))
                        .multilineTextAlignment(.center)
                        .srgFont(.H3)
                        .padding()

                    Text(NSLocalizedString("Need help or want to share a suggestion? Write to us.", comment: "Description of the screen showing the QR code to send a feedback or contact support"))
                        .multilineTextAlignment(.center)
                        .srgFont(.subtitle1)
                        .padding()
                }
                .frame(maxWidth: geometry.size.width / 3)

                Spacer()

                qrCodeView
                    .resizable()
                    .scaledToFit()
                    .frame(width: geometry.size.width / 4)

                Spacer()
                Spacer()
            }
            .frame(maxHeight: .infinity)
        }
    }

    private var qrCodeView: Image {
        if let qrCodeImage = generateQRCode() {
            Image(uiImage: qrCodeImage)
                .interpolation(.none)
        } else {
            Image(systemName: "xmark.circle")
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
    SupportFormView(formURL: URL(string: "www.srgssr.com")!)
}
