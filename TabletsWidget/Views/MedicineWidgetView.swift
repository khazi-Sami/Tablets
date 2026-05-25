import SwiftUI
import WidgetKit

struct MedicineWidgetView: View {
    @Environment(\.widgetFamily) private var family
    @Environment(\.colorScheme) private var colorScheme
    let entry: MedicineWidgetEntry

    var body: some View {
        Group {
            switch family {
            case .systemSmall:
                HomeScreenSmallView(entry: entry)
            case .accessoryRectangular, .accessoryCircular:
                LockScreenWidgetView(entry: entry)
            case .systemMedium:
                HomeScreenMediumView(entry: entry)
            case .systemLarge:
                HomeScreenLargeView(entry: entry)
            default:
                HomeScreenSmallView(entry: entry)
            }
        }
        .widgetURL(widgetURL)
        .widgetBrandBackground(colorScheme)
        .widgetBackground()
    }

    private var widgetURL: URL? {
        if let id = entry.nextMedicineID {
            return URL(string: "tablets://medicine/\(id)")
        }
        if entry.hasAnyMedicines {
            return URL(string: "tablets://medicines")
        }
        return URL(string: "tablets://")
    }
}

private extension View {
    @ViewBuilder
    func widgetBackground() -> some View {
        if #available(iOSApplicationExtension 17.0, *) {
            containerBackground(.background, for: .widget)
        } else {
            background(Color(.systemBackground))
        }
    }
}

struct TabletsMedicinesWidget: Widget {
    let kind = "TabletsMedicinesWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TabletsWidgetProvider()) { entry in
            MedicineWidgetView(entry: entry)
        }
        .configurationDisplayName("Tablets Medicines")
        .description("Track medicine adherence and next dose.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .accessoryRectangular, .accessoryCircular])
    }
}
