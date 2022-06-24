//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

// MARK: View

struct NotificationCell: View {
    let notification: UserNotification
    
    @Environment(\.isEditing) private var isEditing
    @Environment(\.isSelected) private var isSelected
    
    var body: some View {
        HStack(spacing: 0) {
            ImageView(source: notification.imageURL)
                .aspectRatio(16 / 9, contentMode: .fit)
                .selectionAppearance(when: isSelected, while: isEditing)
                .cornerRadius(LayoutStandardViewCornerRadius)
                .layoutPriority(1)
            DescriptionView(notification: notification)
                .padding(.horizontal, 10)
        }
        .accessibilityElement(label: accessibilityLabel, hint: accessibilityHint, traits: accessibilityTraits)
    }
    
    /// Behavior: h-exp, v-exp
    private struct DescriptionView: View {
        let notification: UserNotification
        
        private var title: String {
            let date = DateFormatter.play_relativeShort.string(from: notification.date)
            
            let title = notification.title
            if !title.isEmpty {
                // Unbreakable spaces before / after the separator
                return "\(title) · \(date)"
            }
            else {
                return date
            }
        }
        
        var body: some View {
            VStack(alignment: .leading) {
                HStack(alignment: .top) {
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

// MARK: Accessibility

private extension NotificationCell {
    var accessibilityLabel: String? {
        let title = notification.title
        if !title.isEmpty {
            return "\(title), \(notification.body)"
        }
        else {
            return notification.body
        }
    }
    
    var accessibilityHint: String? {
        return isEditing ? PlaySRGAccessibilityLocalizedString("Toggles selection.", comment: "Notification cell hint in edit mode") : nil
    }
    
    var accessibilityTraits: AccessibilityTraits {
        return isSelected ? .isSelected : []
    }
}

// MARK: Size

class NotificationCellSize: NSObject {
    @objc static func fullWidth() -> NSCollectionLayoutSize {
        return NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(84))
    }
}

// MARK: Preview

struct NotificationCell_Previews: PreviewProvider {
    private static let size = NotificationCellSize.fullWidth().previewSize

    static var previews: some View {
        NotificationCell(notification: Mock.notification(.standard))
            .previewLayout(.fixed(width: size.width, height: size.height))
        NotificationCell(notification: Mock.notification(.overflow))
            .previewLayout(.fixed(width: size.width, height: size.height))
    }
}
