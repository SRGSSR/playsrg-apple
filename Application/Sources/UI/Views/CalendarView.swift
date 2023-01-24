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
    @State private var selectedDate = Date()
    @FirstResponder private var firstResponder
    
    var body: some View {
        VStack {
            DatePicker("", selection: $selectedDate, displayedComponents: [.date])
                .datePickerStyle(GraphicalDatePickerStyle())
                .colorMultiply(.white)
                .accentColor(.red)
            
            Divider()
            
            ExpandingButton(label: NSLocalizedString("OK", comment: "Title of the button to validate date settings")) {
                firstResponder.sendAction(#selector(CalendarViewActions.close))
            }
            .frame(height: 40)
            .responderChain(from: firstResponder)
        }
        .frame(maxWidth: 340)
        .padding()
        .background(Color.srgGray16.cornerRadius(30))
        .onAppear {
            selectedDate = model.day.date
        }
        .onDisappear {
            AnalyticsClickEvent.tvGuideCalendar(to: selectedDate).send()
            model.switchToDay(SRGDay(from: selectedDate))
        }
    }
}

// MARK: Preview

struct CalendarView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            CalendarView(model: ProgramGuideViewModel(date: Date()))
            CalendarView(model: ProgramGuideViewModel(date: Date()))
                .frame(width: 600, height: 600)
        }
        .previewLayout(.sizeThatFits)
    }
}
