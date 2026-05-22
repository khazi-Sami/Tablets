import Foundation
import HealthKit
import Observation

@Observable
final class HealthKitWriteService {
    private let service: HealthKitService

    init(service: HealthKitService) {
        self.service = service
    }

    func writeBP(systolic: Double, diastolic: Double, date: Date) async -> Bool {
        guard service.isAvailable,
              let correlationType = HKCorrelationType.correlationType(forIdentifier: .bloodPressure),
              let systolicType = HKQuantityType.quantityType(forIdentifier: .bloodPressureSystolic),
              let diastolicType = HKQuantityType.quantityType(forIdentifier: .bloodPressureDiastolic),
              service.authorizationStatus(for: systolicType) == .sharingAuthorized,
              service.authorizationStatus(for: diastolicType) == .sharingAuthorized else { return false }

        let unit = HKUnit.millimeterOfMercury()
        let systolicSample = HKQuantitySample(type: systolicType, quantity: HKQuantity(unit: unit, doubleValue: systolic), start: date, end: date)
        let diastolicSample = HKQuantitySample(type: diastolicType, quantity: HKQuantity(unit: unit, doubleValue: diastolic), start: date, end: date)
        let correlation = HKCorrelation(type: correlationType, start: date, end: date, objects: [systolicSample, diastolicSample])
        return await save(correlation)
    }

    func writeBloodSugar(value: Double, date: Date) async -> Bool {
        await writeQuantity(.bloodGlucose, value: value / 18.0, unit: HKUnit(from: "mmol/L"), date: date)
    }

    func writeWeight(kg: Double, date: Date) async -> Bool {
        await writeQuantity(.bodyMass, value: kg, unit: .gramUnit(with: .kilo), date: date)
    }

    func writeTemperature(celsius: Double, date: Date) async -> Bool {
        await writeQuantity(.bodyTemperature, value: celsius, unit: .degreeCelsius(), date: date)
    }

    func writeOxygen(percentage: Double, date: Date) async -> Bool {
        await writeQuantity(.oxygenSaturation, value: percentage / 100.0, unit: .percent(), date: date)
    }

    func writeHeartRate(bpm: Double, date: Date) async -> Bool {
        await writeQuantity(.heartRate, value: bpm, unit: HKUnit.count().unitDivided(by: .minute()), date: date)
    }

    private func writeQuantity(_ identifier: HKQuantityTypeIdentifier, value: Double, unit: HKUnit, date: Date) async -> Bool {
        guard service.isAvailable,
              let type = HKQuantityType.quantityType(forIdentifier: identifier),
              service.authorizationStatus(for: type) == .sharingAuthorized else { return false }
        let sample = HKQuantitySample(type: type, quantity: HKQuantity(unit: unit, doubleValue: value), start: date, end: date)
        return await save(sample)
    }

    private func save(_ object: HKObject) async -> Bool {
        await withCheckedContinuation { continuation in
            service.store().save(object) { success, error in
                if let error {
                    print("[HealthKitWriteService] Save failed: \(error)")
                }
                continuation.resume(returning: success && error == nil)
            }
        }
    }
}
