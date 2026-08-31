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

    /// Fetches the most recent night's sleep by clustering "asleep" samples:
    /// samples separated by gaps over 3 hours are separate sessions, so an
    /// afternoon nap no longer merges with last night into a 17-hour "night".
    /// The chosen session is the longest one in the trailing 24 hours.
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
        guard !asleep.isEmpty else { return nil }

        // Cluster into sessions on >3h gaps, keep the longest session.
        let maxGap: TimeInterval = 3 * 60 * 60
        var sessions: [(start: Date, end: Date)] = []
        var current = (start: asleep[0].startDate, end: asleep[0].endDate)
        for sample in asleep.dropFirst() {
            if sample.startDate.timeIntervalSince(current.end) > maxGap {
                sessions.append(current)
                current = (sample.startDate, sample.endDate)
            } else {
                current.end = max(current.end, sample.endDate)
            }
        }
        sessions.append(current)

        guard let night = sessions.max(by: {
            $0.end.timeIntervalSince($0.start) < $1.end.timeIntervalSince($1.start)
        }) else { return nil }
        // A "night" under 2h is probably just a nap — don't prefill from it.
        guard night.end.timeIntervalSince(night.start) >= 2 * 60 * 60 else { return nil }
        return SleepSample(bedtime: night.start, wakeTime: night.end)
        #else
        return nil
        #endif
    }

    /// True when the user has already responded to the HealthKit prompt for
    /// sleep data — used to prefill silently without triggering a dialog.
    var hasRequestedAuthorization: Bool {
        #if canImport(HealthKit)
        guard isAvailable, let sleepType else { return false }
        return store.authorizationStatus(for: sleepType) != .notDetermined
        #else
        return false
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
