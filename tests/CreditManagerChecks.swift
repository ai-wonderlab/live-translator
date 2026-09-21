import Foundation

final class MemoryCloud: UbiquitousKeyValueStoring {
    var values: [String: Int64] = [:]
    func longLong(forKey key: String) -> Int64 { values[key] ?? 0 }
    func set(_ value: Int64, forKey key: String) { values[key] = value }
    func synchronize() -> Bool { true }
}

@main
struct CreditManagerChecks {
    @MainActor
    static func main() {
        let suite = "CreditManagerChecks.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let cloud = MemoryCloud()
        let credits = CreditManager(defaults: defaults, cloudStore: cloud)

        credits.deduct(recordingSeconds: 2.1)
        precondition(credits.remainingFreeTrialSeconds == 1797, "Round recording up, not a fixed 20s")
        credits.deduct(recordingSeconds: 1)
        precondition(credits.remainingFreeTrialSeconds == 1796, "Whole seconds are not overcharged")
        for duration in [0.0, -1, .nan, .infinity] {
            credits.deduct(recordingSeconds: duration)
        }
        precondition(credits.remainingFreeTrialSeconds == 1796, "Invalid durations must not charge")

        credits.addSeconds(100)
        for _ in 0..<29 { credits.deduct(recordingSeconds: 60) }
        credits.deduct(recordingSeconds: 54)
        precondition(credits.remainingFreeTrialSeconds == 2)
        credits.deduct(recordingSeconds: 5)
        precondition(credits.remainingFreeTrialSeconds == 0)
        precondition(credits.remainingSeconds == 97, "Carry deduction across trial/purchased boundary")

        let reloaded = CreditManager(defaults: defaults, cloudStore: cloud)
        precondition(reloaded.remainingSeconds == 97 && reloaded.remainingFreeTrialSeconds == 0,
                     "Both balances must survive reload")
        reloaded.deduct(recordingSeconds: 1.2)
        precondition(reloaded.remainingSeconds == 95)
        reloaded.deduct(recordingSeconds: .greatestFiniteMagnitude)
        precondition(reloaded.remainingSeconds == 35, "Preserve 60-second cap without overflow")
        reloaded.deduct(recordingSeconds: 60)
        precondition(reloaded.totalRemainingSeconds == 0 && !reloaded.hasCredits)
        reloaded.deduct(recordingSeconds: 3)
        precondition(reloaded.totalRemainingSeconds == 0)
        print("CreditManager checks passed: duration, rounding, invalid inputs, trial crossover, persistence, exhaustion")
    }
}
