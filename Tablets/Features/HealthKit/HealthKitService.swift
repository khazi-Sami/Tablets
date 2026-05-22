import Foundation
import HealthKit
import Observation

@Observable
final class HealthKitService {
    private let healthStore = HKHealthStore()
    private(set) var isAuthorized = false

    var isAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    var readTypes: Set<HKObjectType> {
        var types: Set<HKObjectType> = []
        [
            HKQuantityType.quantityType(forIdentifier: .stepCount),
            HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned),
            HKQuantityType.quantityType(forIdentifier: .restingHeartRate),
            HKQuantityType.quantityType(forIdentifier: .heartRate),
            HKQuantityType.quantityType(forIdentifier: .oxygenSaturation),
            HKQuantityType.quantityType(forIdentifier: .bodyMass)
        ].compactMap { $0 }.forEach { types.insert($0) }
        if let sleep = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) {
            types.insert(sleep)
        }
        return types
    }

    var writeTypes: Set<HKSampleType> {
        [
            HKQuantityType.quantityType(forIdentifier: .bloodPressureSystolic),
            HKQuantityType.quantityType(forIdentifier: .bloodPressureDiastolic),
            HKQuantityType.quantityType(forIdentifier: .bloodGlucose),
            HKQuantityType.quantityType(forIdentifier: .bodyMass),
            HKQuantityType.quantityType(forIdentifier: .bodyTemperature),
            HKQuantityType.quantityType(forIdentifier: .oxygenSaturation),
            HKQuantityType.quantityType(forIdentifier: .heartRate)
        ].compactMap { $0 }.reduce(into: Set<HKSampleType>()) { $0.insert($1) }
    }

    func requestAuthorization() async -> Bool {
        guard isAvailable else {
            isAuthorized = false
            return false
        }

        let granted = await withCheckedContinuation { continuation in
            healthStore.requestAuthorization(toShare: writeTypes, read: readTypes) { success, error in
                if let error {
                    print("[HealthKitService] Authorization failed: \(error)")
                }
                continuation.resume(returning: success && error == nil)
            }
        }
        isAuthorized = granted
        UserHealthProfile.healthKitEnabled = granted
        return granted
    }

    func refreshAuthorizationStatus() {
        guard isAvailable else {
            isAuthorized = false
            return
        }
        if let heartRate = HKQuantityType.quantityType(forIdentifier: .heartRate) {
            isAuthorized = authorizationStatus(for: heartRate) != .notDetermined || UserHealthProfile.healthKitEnabled
        } else {
            isAuthorized = UserHealthProfile.healthKitEnabled
        }
    }

    func authorizationStatus(for type: HKObjectType) -> HKAuthorizationStatus {
        healthStore.authorizationStatus(for: type)
    }

    func store() -> HKHealthStore {
        healthStore
    }
}
