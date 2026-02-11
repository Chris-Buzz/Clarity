import HealthKit
import Foundation

/// Provides HealthKit read/write access for sleep, steps, heart rate, HRV, and mindful sessions.
/// Computes correlations between sleep and screen time when enough data is available.
class HealthKitService {
    static let shared = HealthKitService()
    private let healthStore = HKHealthStore()

    private init() {}

    /// Whether HealthKit is available on this device.
    var isAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    // MARK: - Authorization

    /// Request read/write authorization for all relevant HealthKit types.
    func requestAuthorization() async throws {
        guard isAvailable else { return }

        var readTypes: Set<HKObjectType> = [
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.categoryType(forIdentifier: .mindfulSession)!,
        ]

        // iOS 18+: State of Mind
        if #available(iOS 18.0, *) {
            if let stateOfMind = HKObjectType.stateOfMindType() {
                readTypes.insert(stateOfMind)
            }
        }

        let writeTypes: Set<HKSampleType> = [
            HKObjectType.categoryType(forIdentifier: .mindfulSession)!
        ]

        try await healthStore.requestAuthorization(toShare: writeTypes, read: readTypes)
    }

    // MARK: - Sleep

    /// Fetch total sleep hours from last night (8pm yesterday to noon today).
    func fetchSleepData() async -> Double? {
        guard isAvailable else { return nil }
        let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!

        let calendar = Calendar.current
        let now = Date()
        // Last night window: 8pm yesterday to noon today
        guard let startOfToday = calendar.date(bySettingHour: 0, minute: 0, second: 0, of: now),
              let windowStart = calendar.date(byAdding: .hour, value: -4, to: startOfToday),
              let windowEnd = calendar.date(byAdding: .hour, value: 12, to: startOfToday)
        else { return nil }

        let predicate = HKQuery.predicateForSamples(
            withStart: windowStart, end: windowEnd, options: .strictStartDate
        )
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: sleepType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                guard error == nil, let samples = samples as? [HKCategorySample] else {
                    continuation.resume(returning: nil)
                    return
                }

                // Sum durations of actual sleep stages (not inBed)
                let sleepValues: Set<Int> = [
                    HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue,
                    HKCategoryValueSleepAnalysis.asleepCore.rawValue,
                    HKCategoryValueSleepAnalysis.asleepDeep.rawValue,
                    HKCategoryValueSleepAnalysis.asleepREM.rawValue,
                ]

                var totalSeconds: TimeInterval = 0
                for sample in samples where sleepValues.contains(sample.value) {
                    totalSeconds += sample.endDate.timeIntervalSince(sample.startDate)
                }

                let hours = totalSeconds / 3600.0
                continuation.resume(returning: hours > 0 ? hours : nil)
            }
            healthStore.execute(query)
        }
    }

    // MARK: - Steps

    /// Fetch today's cumulative step count.
    func fetchStepCount() async -> Int? {
        guard isAvailable else { return nil }
        let stepType = HKObjectType.quantityType(forIdentifier: .stepCount)!

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(
            withStart: startOfDay, end: Date(), options: .strictStartDate
        )

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: stepType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, statistics, error in
                guard error == nil, let sum = statistics?.sumQuantity() else {
                    continuation.resume(returning: nil)
                    return
                }
                continuation.resume(returning: Int(sum.doubleValue(for: .count())))
            }
            healthStore.execute(query)
        }
    }

    // MARK: - Heart Rate Variability

    /// Fetch the most recent HRV SDNN value in milliseconds.
    func fetchHeartRateVariability() async -> Double? {
        guard isAvailable else { return nil }
        let hrvType = HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!
        return await fetchMostRecentQuantity(type: hrvType, unit: HKUnit.secondUnit(with: .milli))
    }

    // MARK: - Resting Heart Rate

    /// Fetch today's resting heart rate in BPM.
    func fetchRestingHeartRate() async -> Double? {
        guard isAvailable else { return nil }
        let hrType = HKObjectType.quantityType(forIdentifier: .heartRate)!
        let unit = HKUnit.count().unitDivided(by: .minute())
        return await fetchMostRecentQuantity(type: hrType, unit: unit)
    }

    // MARK: - Mindful Minutes

    /// Write a mindful session sample to HealthKit.
    func writeMindfulMinutes(start: Date, end: Date) async throws {
        guard isAvailable else { return }
        let mindfulType = HKObjectType.categoryType(forIdentifier: .mindfulSession)!
        let sample = HKCategorySample(
            type: mindfulType,
            value: HKCategoryValue.notApplicable.rawValue,
            start: start,
            end: end
        )
        try await healthStore.save(sample)
    }

    // MARK: - Correlation Analysis

    /// A single day's data point for correlation analysis.
    struct DailySnapshot {
        let sleepHours: Double
        let totalScreenTimeMinutes: Double
    }

    /// Compute a simple Pearson correlation between sleep and screen time.
    /// Returns a human-readable insight string if 7+ snapshots are provided.
    func computeSleepScreenTimeCorrelation(snapshots: [DailySnapshot]) -> String? {
        guard snapshots.count >= 7 else { return nil }

        let n = Double(snapshots.count)
        let sleepValues = snapshots.map(\.sleepHours)
        let screenValues = snapshots.map(\.totalScreenTimeMinutes)

        let meanSleep = sleepValues.reduce(0, +) / n
        let meanScreen = screenValues.reduce(0, +) / n

        var numerator: Double = 0
        var denomSleep: Double = 0
        var denomScreen: Double = 0

        for snapshot in snapshots {
            let ds = snapshot.sleepHours - meanSleep
            let dt = snapshot.totalScreenTimeMinutes - meanScreen
            numerator += ds * dt
            denomSleep += ds * ds
            denomScreen += dt * dt
        }

        let denominator = sqrt(denomSleep * denomScreen)
        guard denominator > 0 else { return nil }

        let r = numerator / denominator

        if r < -0.5 {
            return "Your data shows more screen time is linked to less sleep. Reducing evening usage could help."
        } else if r > 0.5 {
            return "Interestingly, your sleep and screen time are positively correlated. Your habits may already be well-balanced."
        } else {
            return "No strong link between your screen time and sleep yet. Keep tracking for better insights."
        }
    }

    // MARK: - Private Helpers

    private func fetchMostRecentQuantity(type: HKQuantityType, unit: HKUnit) async -> Double? {
        let sortDescriptor = NSSortDescriptor(
            key: HKSampleSortIdentifierStartDate, ascending: false
        )
        let predicate = HKQuery.predicateForSamples(
            withStart: Calendar.current.startOfDay(for: Date()),
            end: Date(),
            options: .strictStartDate
        )

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: type,
                predicate: predicate,
                limit: 1,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                guard error == nil,
                      let sample = samples?.first as? HKQuantitySample
                else {
                    continuation.resume(returning: nil)
                    return
                }
                continuation.resume(returning: sample.quantity.doubleValue(for: unit))
            }
            healthStore.execute(query)
        }
    }
}
