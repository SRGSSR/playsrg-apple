//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

// MARK: View

struct NotificationCell: View {
    let notification: UserNotification
    
    @Environment(\.isSelected) private var isSelected
    
    var body: some View {
        HStack(spacing: 0) {
            ImageView(source: notification.imageURL)
                .aspectRatio(16 / 9, contentMode: .fit)
                .selectionAppearance(when: isSelected)
                .cornerRadius(LayoutStandardViewCornerRadius)
                .layoutPriority(1)
            DescriptionView(notification: notification)
                .padding(.horizontal, 10)
        }
    }
    
    /// Behavior: h-exp, v-exp
    private struct DescriptionView: View {
        let notification: UserNotification
        
        private var title: String {
            // Unbreakable spaces before / after the separator
            return "\(notification.title) · \(DateFormatter.play_relativeShort.string(from: notification.date))"
        }
        
        var body: some View {
            VStack(alignment: .leading) {
                HStack {
                    Text(title)
                        .lineLimit(2)
                        .foregroundColor(.srgGray96)
                    if !notification.isRead {
                        Spacer()
                        Text("●")
                            .foregroundColor(Color(.play_notificationRed))
                    }
                }
                .srgFont(.subtitle1)
                
                Text(notification.body)
                    .srgFont(.H4)
                    .lineLimit(2)
                    .foregroundColor(.srgGrayC7)
                    .layoutPriority(1)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }
}
