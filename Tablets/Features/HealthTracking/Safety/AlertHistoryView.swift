import SwiftUI

struct AlertHistoryView: View {
    @State private var alerts = HealthSafetyAlertHistoryStore.shared.all()

    var body: some View {
        NavigationStack {
            MedicalBackgroundView {
                ScrollView {
                    VStack(alignment: .leading, spacing: Spacing.medium) {
                        if alerts.isEmpty {
                            EmptyStateView(
                                title: "No safety alerts yet",
                                message: "If a saved reading needs attention, Tablets will show it here with supportive next steps.",
                                systemImage: "checkmark.shield.fill"
                            )
                            .padding(.top, Spacing.xLarge)
                        } else {
                            ForEach(alerts) { alert in
                                HealthAlertView(alert: alert, compact: true)
                            }
                        }
                    }
                    .padding(Spacing.medium)
                }
            }
            .navigationTitle("Safety Alerts")
            .toolbar {
                if !alerts.isEmpty {
                    Button("Clear") {
                        HealthSafetyAlertHistoryStore.shared.clear()
                        alerts = []
                    }
                }
            }
        }
        .onAppear {
            alerts = HealthSafetyAlertHistoryStore.shared.all()
        }
    }
}
