//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import Foundation

// MARK: View controller

final class ProgramGuideCalendarViewController: UIViewController {
    private let model: ProgramGuideViewModel
    
    private weak var calendarView: HostView<CalendarView>!
    
    init(model: ProgramGuideViewModel) {
        self.model = model
        super.init(nibName: nil, bundle: nil)
        
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        let view = UIView(frame: UIScreen.main.bounds)
        view.backgroundColor = .clear
        
        let blurEffect = UIBlurEffect(style: .systemUltraThinMaterialDark)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = view.bounds
        view.addSubview(blurEffectView)
        
        let calendarView = HostView<CalendarView>(frame: .zero)
        calendarView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(calendarView)
        self.calendarView = calendarView
        
        NSLayoutConstraint.activate([
            calendarView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            calendarView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            calendarView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            calendarView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor)
        ])
        
        self.view = view
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        calendarView.content = CalendarView(model: model)
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return Self.play_supportedInterfaceOrientations
    }
}

// MARK: Protocols

extension ProgramGuideCalendarViewController: CalendarViewActions {
    func close() {
        dismiss(animated: true, completion: nil)
    }
}
