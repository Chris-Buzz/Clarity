import WidgetKit
import SwiftUI

struct ClarityEntry: TimelineEntry {
    let date: Date
    let clarityScore: Int
    let streak: Int
    let screenTimeMinutes: Int
}

struct ClarityProvider: TimelineProvider {
    let sharedDefaults = UserDefaults(suiteName: "group.com.clarity-focus")

    func placeholder(in context: Context) -> ClarityEntry {
        ClarityEntry(date: Date(), clarityScore: 78, streak: 4, screenTimeMinutes: 123)
    }

    func getSnapshot(in context: Context, completion: @escaping (ClarityEntry) -> Void) {
        let score = sharedDefaults?.integer(forKey: "clarityScore") ?? 0
        let streak = sharedDefaults?.integer(forKey: "streak") ?? 0
        let screenTime = sharedDefaults?.integer(forKey: "dailyScreenTime") ?? 0
        completion(ClarityEntry(date: Date(), clarityScore: score, streak: streak, screenTimeMinutes: screenTime))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ClarityEntry>) -> Void) {
        let score = sharedDefaults?.integer(forKey: "clarityScore") ?? 0
        let streak = sharedDefaults?.integer(forKey: "streak") ?? 0
        let screenTime = sharedDefaults?.integer(forKey: "dailyScreenTime") ?? 0
        let entry = ClarityEntry(date: Date(), clarityScore: score, streak: streak, screenTimeMinutes: screenTime)
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }
}

struct ClarityWidgetView: View {
    let entry: ClarityEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            smallWidget
        case .systemMedium:
            mediumWidget
        default:
            smallWidget
        }
    }

    var smallWidget: some View {
        VStack(spacing: 8) {
            Text("CLARITY")
                .font(.custom("SpaceMono-Regular", size: 9))
                .tracking(4)
                .foregroundColor(Color(red: 249/255, green: 115/255, blue: 22/255))
            Text("\(entry.clarityScore)")
                .font(.custom("PlayfairDisplay-Regular", size: 48))
                .foregroundColor(.white)
            HStack(spacing: 12) {
                Label("\(entry.streak)", systemImage: "flame.fill")
                    .font(.custom("Outfit-Medium", size: 12))
                    .foregroundColor(Color(red: 249/255, green: 115/255, blue: 22/255))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 3/255, green: 3/255, blue: 3/255))
    }

    var mediumWidget: some View {
        HStack(spacing: 16) {
            // Score
            VStack(spacing: 4) {
                Text("CLARITY")
                    .font(.custom("SpaceMono-Regular", size: 9))
                    .tracking(4)
                    .foregroundColor(Color(red: 249/255, green: 115/255, blue: 22/255))
                Text("\(entry.clarityScore)")
                    .font(.custom("PlayfairDisplay-Regular", size: 42))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)

            // Divider
            Rectangle()
                .fill(.white.opacity(0.15))
                .frame(width: 1)
                .padding(.vertical, 8)

            // Stats
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "flame.fill")
                        .foregroundColor(Color(red: 249/255, green: 115/255, blue: 22/255))
                    Text("\(entry.streak) day streak")
                        .font(.custom("Outfit-Regular", size: 13))
                        .foregroundColor(.white.opacity(0.7))
                }
                HStack {
                    Image(systemName: "clock")
                        .foregroundColor(.white.opacity(0.35))
                    Text("\(entry.screenTimeMinutes / 60)h \(entry.screenTimeMinutes % 60)m")
                        .font(.custom("Outfit-Regular", size: 13))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 3/255, green: 3/255, blue: 3/255))
    }
}

struct ClarityWidget: Widget {
    let kind: String = "ClarityWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ClarityProvider()) { entry in
            ClarityWidgetView(entry: entry)
        }
        .configurationDisplayName("Clarity Score")
        .description("Track your clarity score and streak.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
