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

    private static let creditSecondsKey = "creditSeconds"
    private static let freeTrialConsumedKey = "freeTrialConsumedSeconds"

    @Published private(set) var remainingSeconds: Int
    @Published private(set) var freeTrialConsumedSeconds: Int

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
        observeCloudChangesIfNeeded()
        refreshFromStorage()
    }

    deinit {
        if let cloudSyncObserver {
            NotificationCenter.default.removeObserver(cloudSyncObserver)
        }
    }

    /// Charge only successful recordings, rounded up to a whole second.
    /// Consume trial time first, then any purchased balance in the same call.
    func deductTranslation(recordedDuration: TimeInterval) {
        guard recordedDuration.isFinite, recordedDuration > 0 else { return }
        let deduction = Int(min(recordedDuration.rounded(.up), Double(totalRemainingSeconds)))
        let trialDeduction = min(remainingFreeTrialSeconds, deduction)
        freeTrialConsumedSeconds += trialDeduction
        defaults.set(freeTrialConsumedSeconds, forKey: Self.freeTrialConsumedKey)

        let purchasedDeduction = deduction - trialDeduction
        if purchasedDeduction > 0 {
            remainingSeconds -= purchasedDeduction
            savePurchasedSeconds()
        }
    }

    func addSeconds(_ seconds: Int) {
        guard seconds > 0 else { return }
        remainingSeconds += seconds
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
