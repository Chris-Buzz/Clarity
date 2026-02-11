import Foundation
import Observation
import SwiftUI
import HealthKit

// MARK: - Health Manager

/// Reads sleep, steps, HRV from HealthKit and writes mindful minutes after focus sessions.
@Observable
class HealthManager {
    var todaySleep: Double? // hours
    var todaySteps: Int?
    var todayHRV: Double? // ms
    var isAuthorized: Bool = false

    private let store = HKHealthStore()

    // Types we read
    private var readTypes: Set<HKObjectType> {
        let types: [HKObjectType?] = [
            HKCategoryType.categoryType(forIdentifier: .sleepAnalysis),
            HKQuantityType.quantityType(forIdentifier: .stepCount),
            HKQuantityType.quantityType(forIdentifier: .heartRate),
            HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN),
            HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned),
            HKCategoryType.categoryType(forIdentifier: .mindfulSession),
        ]
        return Set(types.compactMap { $0 })
    }

    // Types we write
    private var writeTypes: Set<HKSampleType> {
        guard let mindful = HKCategoryType.categoryType(forIdentifier: .mindfulSession) else {
            return []
        }
        return [mindful]
    }

    // MARK: - Authorization

    func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else { return }

        try await store.requestAuthorization(toShare: writeTypes, read: readTypes)
        await MainActor.run { isAuthorized = true }
    }

    // MARK: - Fetch All Today Data

    func fetchTodayData() async {
        async let sleep = fetchSleepData()
        async let steps = fetchStepCount()
        async let hrv = fetchHRV()

        let (s, st, h) = await (sleep, steps, hrv)
        await MainActor.run {
            todaySleep = s
            todaySteps = st
            todayHRV = h
        }
    }

    // MARK: - Sleep (hours last night)

    func fetchSleepData() async -> Double? {
        guard let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) else { return nil }

        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        // Look back to 8pm yesterday to capture full night
        let start = calendar.date(byAdding: .hour, value: -4, to: startOfDay)!
        let predicate = HKQuery.predicateForSamples(withStart: start, end: now, options: .strictStartDate)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: sleepType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, samples, _ in
                guard let samples = samples as? [HKCategorySample] else {
                    continuation.resume(returning: nil)
                    return
                }
                // Sum only asleep intervals (not inBed)
                let asleepSeconds = samples
                    .filter { $0.value != HKCategoryValueSleepAnalysis.inBed.rawValue }
                    .reduce(0.0) { $0 + $1.endDate.timeIntervalSince($1.startDate) }
                continuation.resume(returning: asleepSeconds / 3600.0)
            }
            store.execute(query)
        }
    }

    // MARK: - Steps

    func fetchStepCount() async -> Int? {
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return nil }

        let start = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: start, end: Date(), options: .strictStartDate)

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: stepType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, _ in
                let steps = result?.sumQuantity()?.doubleValue(for: .count())
                continuation.resume(returning: steps.map { Int($0) })
            }
            store.execute(query)
        }
    }

    // MARK: - HRV

    private func fetchHRV() async -> Double? {
        guard let hrvType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN) else { return nil }

        let start = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: start, end: Date(), options: .strictStartDate)
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: hrvType,
                predicate: predicate,
                limit: 1,
                sortDescriptors: [sort]
            ) { _, samples, _ in
                let value = (samples?.first as? HKQuantitySample)?
                    .quantity.doubleValue(for: .secondUnit(with: .milli))
                continuation.resume(returning: value)
            }
            store.execute(query)
        }
    }

    // MARK: - Write Mindful Minutes

    /// Records a mindful session in HealthKit after a completed focus session.
    func writeMindfulMinutes(start: Date, end: Date) async {
        guard let mindfulType = HKCategoryType.categoryType(forIdentifier: .mindfulSession) else { return }

        let sample = HKCategorySample(
            type: mindfulType,
            value: 0,
            start: start,
            end: end
        )

        do {
            try await store.save(sample)
        } catch {
            print("[HealthManager] Failed to write mindful minutes: \(error.localizedDescription)")
        }
    }
}
