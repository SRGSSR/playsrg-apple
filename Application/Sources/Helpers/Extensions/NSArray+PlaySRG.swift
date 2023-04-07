//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import Foundation

extension NSArray {
    /**
     Returns a new array which is the receiver with objects from the specified array removed.
     
     - parameter array: The array of objects to remove from the receiver.
     
     - returns: A new array with objects from the specified array removed.
     */
    @objc func arrayByRemovingObjects(in array: [AnyHashable]) -> NSArray {
        let mutableArray = NSMutableArray(array: self)
        mutableArray.removeObjects(in: array)
        return NSArray(array: mutableArray)
    }
}
