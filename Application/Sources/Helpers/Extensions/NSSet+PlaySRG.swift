//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import Foundation

extension NSSet {
    /**
     Returns a new set which is the receiver with objects from the specified set removed.
     
     - parameter set: The set of objects to remove from the receiver.
     
     - returns: A new set with objects from the specified set removed.
     */
    @objc func setByRemovingObjects(in set: Set<AnyHashable>) -> NSSet {
        let mutableSet = NSMutableSet(set: self)
        mutableSet.minus(set)
        return NSSet(set: mutableSet)
    }
}
