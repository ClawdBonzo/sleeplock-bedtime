import Foundation
#if canImport(HealthKit)
import HealthKit
#endif

/// Reads the user's most recent night of sleep from Apple Health so the daily
/// logger can prefill bedtime + wake time instead of forcing manual entry.
/// Entirely optional and read-only — if HealthKit is unavailable or permission
/// is denied, callers fall back to manual logging.
@MainActor
final class HealthKitService {
    static let shared = HealthKitService()

    struct SleepSample {
        let bedtime: Date
        let wakeTime: Date
    }

    #if canImport(HealthKit)
    private let store = HKHealthStore()

    private var sleepType: HKCategoryType? {
        HKObjectType.categoryType(forIdentifier: .sleepAnalysis)
    }
    #endif

    var isAvailable: Bool {
        #if canImport(HealthKit)
        return HKHealthStore.isHealthDataAvailable()
        #else
        return false
        #endif
    }

    /// Requests read access to sleep analysis. Returns `true` if the request
    /// completed (note: Apple deliberately does not reveal read-grant status, so
    /// a `true` here means "the user has responded", not "access granted").
    func requestAuthorization() async -> Bool {
        #if canImport(HealthKit)
        guard isAvailable, let sleepType else { return false }
        do {
            try await store.requestAuthorization(toShare: [], read: [sleepType])
            return true
        } catch {
            return false
        }
        #else
        return false
        #endif
    }

    /// Fetches the most recent night's sleep — the earliest "asleep" sample start
    /// and the latest "asleep" sample end within the last 24 hours. Returns nil if
    /// no usable sleep data exists.
    func fetchLastNightSleep() async -> SleepSample? {
        #if canImport(HealthKit)
        guard isAvailable, let sleepType else { return nil }

        let now = Date()
        let start = Calendar.current.date(byAdding: .hour, value: -24, to: now) ?? now
        let predicate = HKQuery.predicateForSamples(withStart: start, end: now, options: [])

        let samples: [HKCategorySample] = await withCheckedContinuation { continuation in
            let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
            let query = HKSampleQuery(
                sampleType: sleepType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sort]
            ) { _, results, _ in
                continuation.resume(returning: (results as? [HKCategorySample]) ?? [])
            }
            store.execute(query)
        }

        let asleep = samples.filter { Self.isAsleep($0.value) }
        guard let first = asleep.first, let last = asleep.max(by: { $0.endDate < $1.endDate }) else {
            return nil
        }
        return SleepSample(bedtime: first.startDate, wakeTime: last.endDate)
        #else
        return nil
        #endif
    }

    #if canImport(HealthKit)
    /// True for any "asleep" category value across iOS versions (the granular
    /// core/deep/REM values arrived in iOS 16; `.asleep` is the legacy value).
    private static func isAsleep(_ value: Int) -> Bool {
        if #available(iOS 16.0, *) {
            return value == HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue
                || value == HKCategoryValueSleepAnalysis.asleepCore.rawValue
                || value == HKCategoryValueSleepAnalysis.asleepDeep.rawValue
                || value == HKCategoryValueSleepAnalysis.asleepREM.rawValue
        } else {
            return value == HKCategoryValueSleepAnalysis.asleep.rawValue
        }
    }
    #endif
}
