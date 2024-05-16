//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

protocol PrimaryColorSettable: View {
    var primaryColor: Color { get set }
    func primaryColor(_ color: Color) -> Self
}

extension PrimaryColorSettable {
    func primaryColor(_ color: Color) -> Self {
        var view = self
        view.primaryColor = color
        return view
    }
}

protocol SecondaryColorSettable: View {
    var secondaryColor: Color { get set }
    func secondaryColor(_ color: Color) -> Self
}

extension SecondaryColorSettable {
    func secondaryColor(_ color: Color) -> Self {
        var view = self
        view.secondaryColor = color
        return view
    }
}
