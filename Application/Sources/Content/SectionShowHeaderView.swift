//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

struct SectionShowHeaderView: View {
    let section: SectionModel.Section
    let show: SRGShow?
    
    var body: some View {
        VStack(spacing: 20) {
            ImageView(url: show?.imageUrl(for: .large))
                .aspectRatio(SectionShowHeaderViewSize.aspectRatio, contentMode: .fit)
            VStack(spacing: 12) {
                DescriptionView(section: section)
                ShowAccessButton(show: show)
                Spacer()
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, SectionShowHeaderViewSize.horizontalPadding)
            .padding(.vertical, SectionShowHeaderViewSize.verticalPadding)
        }
    }
    
    private struct DescriptionView: View {
        let section: SectionModel.Section
        
        var body: some View {
            VStack {
                if let title = section.properties.title {
                    Text(title)
                        .srgFont(.H2)
                        .foregroundColor(.white)
                }
                if let summary = section.properties.summary {
                    Text(summary)
                        .srgFont(.body)
                        .foregroundColor(.gray)
                }
            }
        }
    }
    
    private struct ShowAccessButton: View {
        let show: SRGShow?
        
        var body: some View {
            if let show = show {
                Button(action: action, label: {
                    Label(
                        title: {
                            Text(show.title)
                        },
                        icon: {
                            Image("episodes-22")
                        }
                    )
                    .padding(.horizontal, SectionShowHeaderViewSize.horizontalPadding)
                    .padding(.vertical, SectionShowHeaderViewSize.verticalPadding)
                })
                .frame(maxWidth: .infinity, minHeight: 45, alignment: .leading)
                .foregroundColor(.gray)
                .background(Color.white.opacity(0.1))
                .cornerRadius(LayoutStandardViewCornerRadius)
            }
        }
        
        private func action() {
            
        }
    }
}

class SectionShowHeaderViewSize: NSObject {
    fileprivate static let aspectRatio: CGFloat = 16 / 9
    static let horizontalPadding: CGFloat = constant(iOS: 10, tvOS: 16)
    static let verticalPadding: CGFloat = constant(iOS: 8, tvOS: 12)
}

struct SectionShowHeaderView_Previews: PreviewProvider {
    static var previews: some View {
        SectionShowHeaderView(section: SectionModel.Section(.content(Mock.contentSection())), show: Mock.show())
            .previewLayout(.fixed(width: 600, height: 800))
    }
}
