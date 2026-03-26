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
    static let secondsPerTranslation = 20

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

    func deductTranslation() {
        let deduction = Self.secondsPerTranslation

        if remainingFreeTrialSeconds > 0 {
            let consumed = min(Self.freeTrialSeconds, freeTrialConsumedSeconds + deduction)
            freeTrialConsumedSeconds = consumed
            defaults.set(consumed, forKey: Self.freeTrialConsumedKey)
            return
        }

        guard remainingSeconds > 0 else { return }

        remainingSeconds = max(0, remainingSeconds - deduction)
        savePurchasedSeconds()
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
