//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

protocol ColorsSettable: View {
    var primaryColor: Color { get set }
    func primaryColor(_ color: Color) -> Self

    var secondaryColor: Color { get set }
    func secondaryColor(_ color: Color) -> Self
}

extension ColorsSettable {
    func primaryColor(_ color: Color) -> Self {
        var view = self
        view.primaryColor = color
        return view
    }
    
    func secondaryColor(_ color: Color) -> Self {
        var view = self
        view.secondaryColor = color
        return view
    }
}
