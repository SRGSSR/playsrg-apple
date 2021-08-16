//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

// MARK: Contract

@objc protocol CalendarViewActions: AnyObject {
    func close()
}

// MARK: View

/// Behavior: h-hug, v-hug
struct CalendarView: View {
    @ObservedObject var model: ProgramGuideViewModel
    @State private var selectedDate: Date = Date()
    
    var body: some View {
        VStack {
            DatePicker("", selection: $selectedDate, displayedComponents: [.date])
                .datePickerStyle(GraphicalDatePickerStyle())
                .colorMultiply(.white)
                .accentColor(.red)
            Divider()
            ResponderChain { firstResponder in
                HStack {
                    ExpandingButton(label: NSLocalizedString("Cancel", comment: "Title of a cancel button")) {
                        firstResponder.sendAction(#selector(CalendarViewActions.close))
                    }
                    ExpandingButton(label: NSLocalizedString("Done", comment: "Done button title")) {
                        model.switchToDay(SRGDay(from: selectedDate))
                        firstResponder.sendAction(#selector(CalendarViewActions.close))
                    }
                }
                .frame(height: 40)
            }
        }
        .frame(maxWidth: 400)
        .padding()
        .background(Color.srgGray16.cornerRadius(30))
        .onAppear {
            selectedDate = model.dateSelection.day.date
        }
    }
}

// MARK: Preview

struct CalendarView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            CalendarView(model: ProgramGuideViewModel(date: Date()))
                .previewLayout(.sizeThatFits)
            CalendarView(model: ProgramGuideViewModel(date: Date()))
                .frame(width: 600, height: 600)
                .previewLayout(.sizeThatFits)
        }
    }
}
