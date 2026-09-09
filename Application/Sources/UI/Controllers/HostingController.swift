//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

#if os(tvOS)
    /**
     * A hosting controller that applies standard Play interface orientations.
     */
    final class HostingController<Content: View>: UIHostingController<Content> {}
#else
    final class HostingController<Content: View>: UIHostingController<Content>, Oriented {}
#endif
