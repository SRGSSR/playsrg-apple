//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import UIKit

// Properly configured Play standard table view for instantiation in code (with manual cell height).
@objc public class TableView: UITableView {
    override init(frame: CGRect, style: UITableView.Style) {
        super.init(frame: frame, style: style)
        Self.tableViewConfigure(self)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        Self.tableViewConfigure(self)
    }
    
    // Apply standard Play configuration to a given table view (with manual cell height).
    @objc static func tableViewConfigure(_ tableView: UITableView) {
        tableView.backgroundColor = .clear
        tableView.indicatorStyle = .white
        tableView.separatorStyle = .none
        
        // Avoid unreliable content size calculations when row heights are specified (leads to glitches during scrolling or
        // reloads). We do not use automatic cell sizing, so this is best avoided by default. This was the old default behavior,
        // but newer versions of Xcode now enable automatic sizing by default.
        tableView.estimatedRowHeight = 0.0
        tableView.estimatedSectionFooterHeight = 0.0
        tableView.estimatedSectionHeaderHeight = 0.0
    }
}
