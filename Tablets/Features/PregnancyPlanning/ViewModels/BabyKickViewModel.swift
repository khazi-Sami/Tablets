import Combine
import Foundation
import SwiftData
import UIKit

@MainActor
final class BabyKickViewModel: ObservableObject {
    @Published var kickCount = 0
    @Published var isSessionActive = false
    @Published var sessionStartTime: Date?
    @Published var elapsedSeconds = 0
    @Published var recentSessions: [BabyKickLog] = []
    @Published var autoStopEnabled = true
    @Published var didReachTenKicks = false
    @Published var didSaveSession = false
    @Published var savedSession: BabyKickLog?
    private var timer: Timer?

    func startSession() {
        kickCount = 0
        elapsedSeconds = 0
        didReachTenKicks = false
        didSaveSession = false
        savedSession = nil
        sessionStartTime = .now
        isSessionActive = true
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            DispatchQueue.main.async { [weak self] in
                guard let self, let start = self.sessionStartTime else { return }
                self.elapsedSeconds = Int(Date().timeIntervalSince(start))
            }
        }
    }

    func recordKick() {
        if !isSessionActive { startSession() }
        kickCount += 1
        if let start = sessionStartTime {
            elapsedSeconds = Int(Date().timeIntervalSince(start))
        }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        if autoStopEnabled && kickCount >= 10 {
            didReachTenKicks = true
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }

    func stopSession(context: ModelContext, profileId: UUID) {
        let start = sessionStartTime ?? .now
        let duration = max(0, Int(Date().timeIntervalSince(start) / 60))
        let log = BabyKickLog(pregnancyProfileId: profileId, sessionStartedAt: start, sessionEndedAt: .now, kickCount: kickCount, durationMinutes: duration)
        context.insert(log)
        try? context.save()
        isSessionActive = false
        timer?.invalidate()
        savedSession = log
        didSaveSession = true
        loadRecent(context: context, profileId: profileId)
    }

    func loadRecent(context: ModelContext, profileId: UUID) {
        recentSessions = ((try? context.fetch(FetchDescriptor<BabyKickLog>(sortBy: [SortDescriptor(\.sessionStartedAt, order: .reverse)]))) ?? []).filter { $0.pregnancyProfileId == profileId }.prefix(7).map { $0 }
    }
}
