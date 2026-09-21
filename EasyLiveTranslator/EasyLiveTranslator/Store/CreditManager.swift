import Foundation
import Combine

protocol UbiquitousKeyValueStoring: AnyObject {
    func longLong(forKey defaultName: String) -> Int64
    func set(_ value: Int64, forKey aKey: String)
    @discardableResult
    func synchronize() -> Bool
}

extension NSUbiquitousKeyValueStore: UbiquitousKeyValueStoring {}

@MainActor
final class CreditManager: ObservableObject {
    static let shared = CreditManager()

    static let freeTrialSeconds = 1800
    /// Billing is by real recording time (how long the button is held),
    /// clamped so a tap can't cost less than this and a stuck hold can't cost more than `maxSecondsPerTranslation`.
    static let minSecondsPerTranslation = 1
    static let maxSecondsPerTranslation = 60

    private static let creditSecondsKey = "creditSeconds"
    private static let freeTrialConsumedKey = "freeTrialConsumedSeconds"
    private static let hasEverPurchasedKey = "hasEverPurchased"

    @Published private(set) var remainingSeconds: Int
    @Published private(set) var freeTrialConsumedSeconds: Int
    @Published private(set) var hasEverPurchased: Bool

    private let defaults: UserDefaults
    private let cloudStore: UbiquitousKeyValueStoring
    private var cloudSyncObserver: NSObjectProtocol?

    var remainingFreeTrialSeconds: Int {
        max(0, Self.freeTrialSeconds - freeTrialConsumedSeconds)
    }

    var totalRemainingSeconds: Int {
        remainingFreeTrialSeconds + remainingSeconds
    }

    var hasCredits: Bool {
        remainingFreeTrialSeconds > 0 || remainingSeconds > 0
    }

    var remainingMinutesText: String {
        Self.format(seconds: totalRemainingSeconds)
    }

    var displayTime: String {
        Self.format(seconds: totalRemainingSeconds)
    }

    init(
        defaults: UserDefaults = .standard,
        cloudStore: UbiquitousKeyValueStoring = NSUbiquitousKeyValueStore.default
    ) {
        self.defaults = defaults
        self.cloudStore = cloudStore
        self.remainingSeconds = max(0, Int(cloudStore.longLong(forKey: Self.creditSecondsKey)))
        self.freeTrialConsumedSeconds = max(0, defaults.integer(forKey: Self.freeTrialConsumedKey))
        self.hasEverPurchased = defaults.bool(forKey: Self.hasEverPurchasedKey)
        observeCloudChangesIfNeeded()
        refreshFromStorage()
    }

    deinit {
        if let cloudSyncObserver {
            NotificationCenter.default.removeObserver(cloudSyncObserver)
        }
    }

    /// Deducts the real recording duration. Free-trial time is consumed first;
    /// any remainder comes out of purchased time.
    func deduct(recordingSeconds: Double) {
        guard recordingSeconds.isFinite, recordingSeconds > 0 else { return }
        var deduction = Int(min(Double(Self.maxSecondsPerTranslation),
                                max(Double(Self.minSecondsPerTranslation), recordingSeconds.rounded(.up))))

        if remainingFreeTrialSeconds > 0 {
            let fromTrial = min(remainingFreeTrialSeconds, deduction)
            freeTrialConsumedSeconds = min(Self.freeTrialSeconds, freeTrialConsumedSeconds + fromTrial)
            defaults.set(freeTrialConsumedSeconds, forKey: Self.freeTrialConsumedKey)
            deduction -= fromTrial
        }

        guard deduction > 0, remainingSeconds > 0 else { return }

        remainingSeconds = max(0, remainingSeconds - deduction)
        savePurchasedSeconds()
    }

    func addSeconds(_ seconds: Int) {
        guard seconds > 0 else { return }
        remainingSeconds += seconds
        hasEverPurchased = true
        defaults.set(true, forKey: Self.hasEverPurchasedKey)
        savePurchasedSeconds()
    }

    func refreshFromStorage() {
        freeTrialConsumedSeconds = min(
            Self.freeTrialSeconds,
            max(0, defaults.integer(forKey: Self.freeTrialConsumedKey))
        )
        remainingSeconds = max(0, Int(cloudStore.longLong(forKey: Self.creditSecondsKey)))
    }

    private func savePurchasedSeconds() {
        cloudStore.set(Int64(remainingSeconds), forKey: Self.creditSecondsKey)
        cloudStore.synchronize()
    }

    private func observeCloudChangesIfNeeded() {
        guard cloudStore is NSUbiquitousKeyValueStore else { return }

        cloudSyncObserver = NotificationCenter.default.addObserver(
            forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: NSUbiquitousKeyValueStore.default,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                self.refreshFromStorage()
            }
        }
    }

    private static func format(seconds: Int) -> String {
        let totalMinutes = max(0, seconds / 60)
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60

        if hours > 0 {
            return "\(hours)h \(minutes)m remaining"
        }

        return "\(totalMinutes) min remaining"
    }
}
