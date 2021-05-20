//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import Combine
import UIKit

// MARK: View controller

class SectionViewController: UIViewController {
    let model: SectionModel
    
    private var cancellables = Set<AnyCancellable>()
    private weak var label: UILabel!
    
    init(section: Content.Section, filter: SectionFiltering) {
        self.model = SectionModel(section: section, filter: filter)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        let view = UIView(frame: UIScreen.main.bounds)
        view.backgroundColor = .play_black
        
        let label = UILabel(frame: view.bounds)
        label.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        label.textAlignment = .center
        view.addSubview(label)
        self.label = label
        
        self.view = view
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = model.title
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(loadMore))
        view.addGestureRecognizer(tapGestureRecognizer)
        
        model.$state
            .sink { [weak self] state in
                self?.reloadData(with: state)
            }
            .store(in: &cancellables)
    }
    
    @objc func loadMore(_ sender: Any) {
        model.loadMore()
    }
    
    private func reloadData(with state: SectionModel.State) {
        switch state {
        case let .loaded(items: items):
            label.text = "\(items.count) items"
        case let .failed(error: error):
            label.text = error.localizedDescription
        case .loading:
            label.text = "Loading"
        }
    }
}

// MARK: Protocols

// TODO: Remaining protocols to implement

#if false

extension PageViewController: PlayApplicationNavigation {
    
}

extension PageViewController: SRGAnalyticsViewTracking {
    
}

#endif
