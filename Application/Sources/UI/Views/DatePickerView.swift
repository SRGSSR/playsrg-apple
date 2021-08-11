//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

/// Behavior: h-hug, v-hug
struct DatePickerView: View {
    @ObservedObject var model: ProgramGuideViewModel
    @State private var selectedDate: Date = Date()
    
    var body: some View {
        VStack {
            DatePicker("", selection: $selectedDate, displayedComponents: [.date])
                .datePickerStyle(GraphicalDatePickerStyle())
                .colorMultiply(.white)
                .accentColor(.srgRed)
            Divider()
            HStack {
                ExpandingButton(label: NSLocalizedString("Cancel", comment: "Title of a cancel button")) {
                    model.isDatePickerPresented = false
                }
                ExpandingButton(label: NSLocalizedString("Done", comment: "Done button title")) {
                    model.atDay(SRGDay(from: selectedDate))
                    model.isDatePickerPresented = false
                }
            }
            .frame(height: 40)
        }
        .padding()
        .background(Color.srgGray16.cornerRadius(30))
        .onAppear {
            selectedDate = model.dateSelection.day.date
        }
    }
}

struct DatePickerView_Previews: PreviewProvider {
    static var previews: some View {
        DatePickerView(model: ProgramGuideViewModel(date: Date()))
            .previewLayout(.sizeThatFits)
    }
}
