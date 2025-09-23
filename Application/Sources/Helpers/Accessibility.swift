//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import Combine
import SwiftUI

@propertyWrapper struct Accessibility<T>: DynamicProperty {
    @ObservedObject private var settings = AccessibilitySettings.shared

    private let keyPath: KeyPath<AccessibilitySettings, T>

    init(_ keyPath: KeyPath<AccessibilitySettings, T>) {
        self.keyPath = keyPath
    }

    var wrappedValue: T {
        settings[keyPath: keyPath]
    }
}

final class AccessibilitySettings: ObservableObject {
    static let shared = AccessibilitySettings()

    // Remark: Some of these are readily accessible as environment values from SwiftUI:
    //           - `accessibilityDifferentiateWithoutColor`,
    //           - `accessibilityReduceTransparency`
    //           - `accessibilityReduceMotion`
    //           - `accessibilityInvertColors`

    @Published var isVoiceOverRunning = UIAccessibility.isVoiceOverRunning
    @Published var isMonoAudioEnabled = UIAccessibility.isMonoAudioEnabled
    @Published var isClosedCaptioningEnabled = UIAccessibility.isClosedCaptioningEnabled
    @Published var isInvertColorsEnabled = UIAccessibility.isInvertColorsEnabled
    @Published var isGuidedAccessEnabled = UIAccessibility.isGuidedAccessEnabled
    @Published var isBoldTextEnabled = UIAccessibility.isBoldTextEnabled
    @Published var buttonShapesEnabled = UIAccessibility.buttonShapesEnabled
    @Published var isGrayscaleEnabled = UIAccessibility.isGrayscaleEnabled
    @Published var isReduceTransparencyEnabled = UIAccessibility.isReduceTransparencyEnabled
    @Published var isReduceMotionEnabled = UIAccessibility.isReduceMotionEnabled
    @Published var prefersCrossFadeTransitions = UIAccessibility.prefersCrossFadeTransitions
    @Published var isVideoAutoplayEnabled = UIAccessibility.isVideoAutoplayEnabled
    @Published var isDarkerSystemColorsEnabled = UIAccessibility.isDarkerSystemColorsEnabled
    @Published var isSwitchControlRunning = UIAccessibility.isSwitchControlRunning
    @Published var isSpeakSelectionEnabled = UIAccessibility.isSpeakSelectionEnabled
    @Published var isSpeakScreenEnabled = UIAccessibility.isSpeakScreenEnabled
    @Published var isShakeToUndoEnabled = UIAccessibility.isShakeToUndoEnabled
    @Published var isAssistiveTouchRunning = UIAccessibility.isAssistiveTouchRunning
    @Published var shouldDifferentiateWithoutColor = UIAccessibility.shouldDifferentiateWithoutColor
    @Published var isOnOffSwitchLabelsEnabled = UIAccessibility.isOnOffSwitchLabelsEnabled

    private init() {
        NotificationCenter.default.weakPublisher(for: UIAccessibility.voiceOverStatusDidChangeNotification)
            .map { _ in UIAccessibility.isVoiceOverRunning }
            .assign(to: &$isVoiceOverRunning)
        NotificationCenter.default.weakPublisher(for: UIAccessibility.monoAudioStatusDidChangeNotification)
            .map { _ in UIAccessibility.isMonoAudioEnabled }
            .assign(to: &$isMonoAudioEnabled)
        NotificationCenter.default.weakPublisher(for: UIAccessibility.closedCaptioningStatusDidChangeNotification)
            .map { _ in UIAccessibility.isClosedCaptioningEnabled }
            .assign(to: &$isClosedCaptioningEnabled)
        NotificationCenter.default.weakPublisher(for: UIAccessibility.invertColorsStatusDidChangeNotification)
            .map { _ in UIAccessibility.isInvertColorsEnabled }
            .assign(to: &$isInvertColorsEnabled)
        NotificationCenter.default.weakPublisher(for: UIAccessibility.guidedAccessStatusDidChangeNotification)
            .map { _ in UIAccessibility.isGuidedAccessEnabled }
            .assign(to: &$isGuidedAccessEnabled)
        NotificationCenter.default.weakPublisher(for: UIAccessibility.boldTextStatusDidChangeNotification)
            .map { _ in UIAccessibility.isBoldTextEnabled }
            .assign(to: &$isBoldTextEnabled)
        NotificationCenter.default.weakPublisher(for: UIAccessibility.buttonShapesEnabledStatusDidChangeNotification)
            .map { _ in UIAccessibility.buttonShapesEnabled }
            .assign(to: &$buttonShapesEnabled)
        NotificationCenter.default.weakPublisher(for: UIAccessibility.grayscaleStatusDidChangeNotification)
            .map { _ in UIAccessibility.isGrayscaleEnabled }
            .assign(to: &$isGrayscaleEnabled)
        NotificationCenter.default.weakPublisher(for: UIAccessibility.reduceTransparencyStatusDidChangeNotification)
            .map { _ in UIAccessibility.isReduceTransparencyEnabled }
            .assign(to: &$isReduceTransparencyEnabled)
        NotificationCenter.default.weakPublisher(for: UIAccessibility.reduceMotionStatusDidChangeNotification)
            .map { _ in UIAccessibility.isReduceMotionEnabled }
            .assign(to: &$isReduceMotionEnabled)
        NotificationCenter.default.weakPublisher(for: UIAccessibility.prefersCrossFadeTransitionsStatusDidChange)
            .map { _ in UIAccessibility.prefersCrossFadeTransitions }
            .assign(to: &$prefersCrossFadeTransitions)
        NotificationCenter.default.weakPublisher(for: UIAccessibility.videoAutoplayStatusDidChangeNotification)
            .map { _ in UIAccessibility.isVideoAutoplayEnabled }
            .assign(to: &$isVideoAutoplayEnabled)
        NotificationCenter.default.weakPublisher(for: UIAccessibility.darkerSystemColorsStatusDidChangeNotification)
            .map { _ in UIAccessibility.isDarkerSystemColorsEnabled }
            .assign(to: &$isDarkerSystemColorsEnabled)
        NotificationCenter.default.weakPublisher(for: UIAccessibility.switchControlStatusDidChangeNotification)
            .map { _ in UIAccessibility.isSwitchControlRunning }
            .assign(to: &$isSwitchControlRunning)
        NotificationCenter.default.weakPublisher(for: UIAccessibility.speakSelectionStatusDidChangeNotification)
            .map { _ in UIAccessibility.isSpeakSelectionEnabled }
            .assign(to: &$isSpeakSelectionEnabled)
        NotificationCenter.default.weakPublisher(for: UIAccessibility.speakScreenStatusDidChangeNotification)
            .map { _ in UIAccessibility.isSpeakScreenEnabled }
            .assign(to: &$isSpeakScreenEnabled)
        NotificationCenter.default.weakPublisher(for: UIAccessibility.shakeToUndoDidChangeNotification)
            .map { _ in UIAccessibility.isShakeToUndoEnabled }
            .assign(to: &$isShakeToUndoEnabled)
        NotificationCenter.default.weakPublisher(for: UIAccessibility.assistiveTouchStatusDidChangeNotification)
            .map { _ in UIAccessibility.isAssistiveTouchRunning }
            .assign(to: &$isAssistiveTouchRunning)
        NotificationCenter.default.weakPublisher(for: UIAccessibility.differentiateWithoutColorDidChangeNotification)
            .map { _ in UIAccessibility.shouldDifferentiateWithoutColor }
            .assign(to: &$shouldDifferentiateWithoutColor)
        NotificationCenter.default.weakPublisher(for: UIAccessibility.onOffSwitchLabelsDidChangeNotification)
            .map { _ in UIAccessibility.isOnOffSwitchLabelsEnabled }
            .assign(to: &$isOnOffSwitchLabelsEnabled)
    }
}
